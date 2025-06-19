import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/course.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';
import 'lecturer_settings_page.dart'; // Import the new settings page

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  _LecturerDashboardState createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Course> _courses = [];
  int _totalCourses = 0;
  int _publishedCourses = 0;
  int _totalEnrollments = 0;
  List<BarChartGroupData> _enrollmentChartData = [];
  List<String> _chartLabels = [];
  String? _userName;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No user logged in');
      final userData = await _firestoreService.getUser(user.uid);
      _courses = await _firestoreService.getLecturerCourses(user.uid);
      _totalCourses = _courses.length;
      _publishedCourses = _courses.where((c) => c.isPublished).length;
      _totalEnrollments = (await Future.wait(
        _courses.map((c) => _firestoreService.getEnrolledStudents(c.id)),
      )).fold(0, (sum, students) => sum + students.length);
      _enrollmentChartData = await _createEnrollmentChartData();
      _chartLabels = _getChartLabels();
      if (mounted) {
        setState(() {
          _userName = userData?['displayName'] ?? 'Lecturer';
          _profileImageUrl = userData?['profileImageUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load dashboard: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _loadData();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Refresh failed: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF6949),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmLogout ?? false) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.login,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to log out: $e', Colors.redAccent);
        }
      }
    }
  }

  void _showAccountDetails() async {
    // No longer showing details, navigating to settings page instead
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LecturerSettingsPage()),
    );
  }

  Future<List<BarChartGroupData>> _createEnrollmentChartData() async {
    final Map<String, int> enrollmentCounts = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: i)));
      enrollmentCounts[date] = 0;
    }
    for (var course in _courses) {
      final enrolledStudents = await _firestoreService.getEnrolledStudents(
        course.id,
      );
      for (var student in enrolledStudents) {
        final enrolledAt =
            student['enrolledAt']?.toDate()?.toString().split(' ')[0];
        if (enrolledAt != null && enrollmentCounts.containsKey(enrolledAt)) {
          enrollmentCounts[enrolledAt] = enrollmentCounts[enrolledAt]! + 1;
        }
      }
    }
    final List<BarChartGroupData> barGroups = [];
    enrollmentCounts.entries.toList().asMap().forEach((index, entry) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: const Color(0xFFFF6949),
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 10,
                color: Colors.grey[100],
              ),
            ),
          ],
        ),
      );
    });
    return barGroups;
  }

  List<String> _getChartLabels() {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => DateFormat('MMM dd').format(now.subtract(Duration(days: 6 - i))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body:
          _isLoading
              ? const Center(child: LoadingIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    toolbarHeight: 60,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Lecturer Dashboard',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: isMobile ? 20 : 24,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF6949), Color(0xFFFF8A65)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    backgroundColor: const Color(0xFFFF6949),
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: _logout,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                        onPressed: _refreshData,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildWelcomeCard(context, isMobile),
                        const SizedBox(height: 24),
                        Text(
                          'Dashboard Overview',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: isMobile ? 24 : 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your courses and analytics',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildOverviewCard(context, isMobile),
                        const SizedBox(height: 24),
                        _buildQuickActionsCard(context, isMobile),
                        const SizedBox(height: 24),
                        _buildEnrollmentTrendsCard(context, isMobile),
                        const SizedBox(height: 24),
                        _buildCoursesCard(context, isMobile),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            '© 2025 Hybrid LMS',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showAccountDetails, // Now navigates to LecturerSettingsPage
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 28,
                backgroundImage:
                    _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                child:
                    _profileImageUrl == null
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        )
                        : null,
                backgroundColor: const Color(0xFFFF6949),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${_userName ?? 'Lecturer'}!',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 20,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View profile and settings',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 12 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFFF6949),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.1 : 1.3,
      children: [
        _buildStatCard(
          'Total Courses',
          _totalCourses,
          Icons.book,
          context,
          isMobile,
          gradient: [const Color(0xFFFF6949), const Color(0xFFFF8A65)],
        ),
        _buildStatCard(
          'Published Courses',
          _publishedCourses,
          Icons.publish,
          context,
          isMobile,
          gradient: [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
        ),
        _buildStatCard(
          'Total Enrollments',
          _totalEnrollments,
          Icons.group,
          context,
          isMobile,
          gradient: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 24 : 28,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quick access to common tasks',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 1.3 : 1.5,
          children: [
            _buildActionButton(
              context,
              label: 'Create Course',
              icon: Icons.add_circle_outline,
              route: Routes.courseEditor,
              isMobile: isMobile,
            ),
            _buildActionButton(
              context,
              label: 'Manage Courses',
              icon: Icons.list_alt,
              route: Routes.courseManagement,
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnrollmentTrendsCard(BuildContext context, bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrollment Trends (Last 7 Days)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFFFF6949),
                    size: 20,
                  ),
                  onPressed: _refreshData,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: isMobile ? 180 : 220,
              child:
                  _enrollmentChartData.isEmpty
                      ? Center(
                        child: Text(
                          'No data available',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      )
                      : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barGroups: _enrollmentChartData,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                    ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  return index < _chartLabels.length
                                      ? Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _chartLabels[index],
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                      : const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color: Colors.grey[200],
                                  strokeWidth: 0.5,
                                ),
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipPadding: const EdgeInsets.all(8),
                              tooltipMargin: 8,
                              tooltipBorder: const BorderSide(
                                color: Color(0xFFFF6949),
                              ),
                              getTooltipColor: (_) => Colors.white,
                              getTooltipItem:
                                  (
                                    group,
                                    groupIndex,
                                    rod,
                                    rodIndex,
                                  ) => BarTooltipItem(
                                    '${rod.toY.toInt()} Enrollments\n${_chartLabels[groupIndex]}',
                                    GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: const Color(0xFFFF6949),
                ),
                const SizedBox(width: 8),
                Text(
                  'Enrollments',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesCard(BuildContext context, bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Courses (${_courses.length})',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Color(0xFFFF6949),
                    size: 20,
                  ),
                  onPressed:
                      () =>
                          Navigator.pushNamed(context, Routes.courseManagement),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_courses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No courses found. Create your first course!',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: isMobile ? 250 : 250,
                child: ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  itemCount: _courses.length,
                  itemBuilder:
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCourseCard(_courses[index], isMobile),
                      ),
                ),
              ),
            if (_courses.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed:
                      () =>
                          Navigator.pushNamed(context, Routes.courseManagement),
                  child: Text(
                    'View All Courses',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF6949),
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, bool isMobile) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => Navigator.pushNamed(
                context,
                Routes.courseEditor,
                arguments: course,
              ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: isMobile ? 20 : 22,
              backgroundColor: const Color(0xFFFF6949),
              child: Text(
                course.title.isNotEmpty ? course.title[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              course.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: isMobile ? 14 : 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(
                  course.isPublished ? Icons.check_circle : Icons.edit,
                  size: isMobile ? 12 : 14,
                  color:
                      course.isPublished ? Colors.green[700] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  course.isPublished ? 'Published' : 'Draft',
                  style: GoogleFonts.poppins(
                    color:
                        course.isPublished
                            ? Colors.green[700]
                            : Colors.grey[600],
                    fontSize: isMobile ? 12 : 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info, color: Color(0xFFFF6949), size: 20),
              onPressed: () => _showCourseDetails(course),
            ),
          ),
        ),
      ),
    );
  }

  void _showCourseDetails(Course course) {
    final moduleCount = course.modules?.length ?? 0;
    final createdAt =
        course.createdAt?.toDate().toString().split('.')[0] ?? 'N/A';
    final category = course.category ?? 'Uncategorized';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.6,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Course Details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDetailRow('Name', course.title),
                          _buildDetailRow('Category', category),
                          _buildDetailRow('Modules', '$moduleCount'),
                          _buildDetailRow('Created At', createdAt),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6949),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    dynamic count,
    IconData icon,
    BuildContext context,
    bool isMobile, {
    required List<Color> gradient,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => print('$title tapped'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isMobile ? 24 : 28, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: isMobile ? 12 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 22,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String route,
    required bool isMobile,
  }) {
    return ElevatedButton(
      onPressed: () async {
        try {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != route) {
            await Navigator.pushNamed(context, route);
          } else {
            _showSnackBar('Already on $label page', const Color(0xFFFF6949));
          }
        } catch (e) {
          _showSnackBar('Navigation failed: $e', Colors.redAccent);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6949),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 12,
          horizontal: isMobile ? 12 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 28 : 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.redAccent
                  ? Icons.error_outline
                  : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
