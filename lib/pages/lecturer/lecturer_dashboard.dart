import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/routes.dart';
import 'package:hybridlms/services/auth_service.dart';
import 'package:hybridlms/services/firestore_service.dart';
import 'package:hybridlms/widgets/loading_indicator.dart';

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
      setState(() {
        _userName = userData?['displayName'] ?? 'Lecturer';
        _profileImageUrl = userData?['profileImageUrl'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load dashboard data: $e',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
        );
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
      // No alert message on refresh failure
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    bool confirmLogout =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmLogout) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to log out: $e',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
            ),
          );
        }
      }
    }
  }

  Future<List<BarChartGroupData>> _createEnrollmentChartData() async {
    final Map<String, int> enrollmentCounts = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i)).toString().split(' ')[0];
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
              width: 14,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 10,
                color: Colors.grey[200],
              ),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    });
    return barGroups;
  }

  List<String> _getChartLabels() {
    final now = DateTime.now();
    final List<String> labels = [];
    for (int i = 6; i >= 0; i--) {
      final date = now
          .subtract(Duration(days: i))
          .toString()
          .split(' ')[0]
          .substring(5);
      labels.add(date);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                    titleSpacing: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Lecturer Dashboard',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
                        ),
                        textAlign: TextAlign.center,
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
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                        onPressed: _refreshData,
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: 16,
                      ),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  '© 2025 Hybrid LMS',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
        onTap: () => Navigator.pushNamed(context, Routes.lecturerSettingsPage),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 22 : 28,
                backgroundImage:
                    _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                child:
                    _profileImageUrl == null
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        )
                        : null,
                backgroundColor: const Color(0xFFFF6949),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_userName!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 20,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your profile and settings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 12 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFFFF6949),
                size: isMobile ? 22 : 26,
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
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.3 : 1.5,
      children: [
        _buildStatCard(
          'Total Courses',
          _totalCourses,
          Icons.book,
          context,
          isMobile,
        ),
        _buildStatCard(
          'Published Courses',
          _publishedCourses,
          Icons.publish,
          context,
          isMobile,
        ),
        _buildStatCard(
          'Total Enrollments',
          _totalEnrollments,
          Icons.group,
          context,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
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
        if (!isMobile)
          _buildActionButton(
            context,
            label: 'View Analytics',
            icon: Icons.analytics,
            route: Routes.analytics,
            isMobile: isMobile,
          ),
      ],
    );
  }

  Widget _buildEnrollmentTrendsCard(BuildContext context, bool isMobile) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                      fontSize: isMobile ? 16 : 20,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFFF6949)),
                    onPressed: _loadData,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: isMobile ? 200 : 280,
                child:
                    _enrollmentChartData.isEmpty
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6949),
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
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: isMobile ? 10 : 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < _chartLabels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _chartLabels[value.toInt()],
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: isMobile ? 10 : 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }
                                    return const Text('');
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
                                tooltipPadding: const EdgeInsets.all(6),
                                tooltipMargin: 6,
                                getTooltipItem: (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) {
                                  return BarTooltipItem(
                                    '${rod.toY.toInt()} Enrollments\n${_chartLabels[groupIndex]}',
                                    GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 10 : 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
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
                  const SizedBox(width: 4),
                  Text(
                    'Enrollments',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesCard(BuildContext context, bool isMobile) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Courses',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 20,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFFFF6949)),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.courseManagement);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_courses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No courses found. Create your first course!',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 12 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                AnimatedList(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  initialItemCount: _courses.length,
                  itemBuilder: (context, index, animation) {
                    final course = _courses[index];
                    return SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF6949).withOpacity(0.1),
                                  Colors.white,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                radius: isMobile ? 18 : 22,
                                backgroundColor: const Color(0xFFFF6949),
                                child: Text(
                                  course.title.isNotEmpty
                                      ? course.title[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isMobile ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                course.title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    course.isPublished
                                        ? Icons.check_circle
                                        : Icons.edit,
                                    size: isMobile ? 12 : 14,
                                    color:
                                        course.isPublished
                                            ? Colors.green[700]
                                            : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    course.isPublished ? 'Published' : 'Draft',
                                    style: GoogleFonts.poppins(
                                      color:
                                          course.isPublished
                                              ? Colors.green[700]
                                              : Colors.grey[600],
                                      fontSize: isMobile ? 10 : 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.info,
                                      color: Color(0xFFFF6949),
                                    ),
                                    onPressed: () => _showCourseDetails(course),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.courseEditor,
                                  arguments: course,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
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
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Details',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Name', course.title),
                _buildDetailRow('Category', category),
                _buildDetailRow('Modules', '$moduleCount'),
                _buildDetailRow('Created At', createdAt),
                const SizedBox(height: 16),
                Align(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6949),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
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
    bool isMobile,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          print('$title details');
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isMobile ? 24 : 28,
                color: const Color(0xFFFF6949),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: isMobile ? 10 : 12,
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
                  color: Colors.black87,
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
    return SizedBox(
      width: isMobile ? 120 : 150,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: isMobile ? 14 : 16, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: isMobile ? 12 : 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 8 : 10,
            horizontal: isMobile ? 10 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFFFF6949),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),
    );
  }
}
