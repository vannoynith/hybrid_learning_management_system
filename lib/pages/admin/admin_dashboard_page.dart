import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../routes.dart';
import '../../models/interaction.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_settings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeUsers = [];
  List<Interaction> _adminInteractions = [];
  String _searchQuery = '';
  String? _interactionError;
  final TextEditingController _searchController = TextEditingController();
  int _activeUserCount = 0;
  int _onlineUserCount = 0;
  double _growthRate = 0.0;
  String _appStatus = 'Stable';
  String? _userName;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _interactionError = null;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No user logged in');

      final userData = await _firestoreService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _userName = userData?['displayName'] as String? ?? 'Admin';
        _profileImageUrl = userData?['profileImageUrl'] as String?;
      });

      final activeUsers = await _firestoreService.getActiveUsers();
      if (!mounted) return;
      setState(() {
        _activeUsers = activeUsers;
        _activeUserCount = activeUsers.length;
      });

      final now = DateTime.now();
      final onlineUserCount =
          activeUsers.where((user) {
            final lastActive = user['lastActive'] as Timestamp?;
            return lastActive != null &&
                lastActive.toDate().isAfter(
                  now.subtract(const Duration(minutes: 15)),
                );
          }).length;

      final newUsers =
          activeUsers.where((user) {
            final timestamp = user['createdAt'] as Timestamp?;
            return timestamp != null &&
                timestamp.toDate().isAfter(
                  now.subtract(const Duration(days: 30)),
                );
          }).length;

      if (!mounted) return;
      setState(() {
        _onlineUserCount = onlineUserCount;
        _growthRate =
            (activeUsers.isNotEmpty ? newUsers / activeUsers.length : 0) * 100;
        _appStatus =
            _growthRate > 5
                ? 'Growing'
                : _growthRate < -2
                ? 'Declining'
                : 'Stable';
      });

      if (userData == null || userData['role'] != 'admin') {
        if (!mounted) return;
        setState(() {
          _interactionError = 'User is not an admin or user data not found';
          _adminInteractions = [];
        });
      } else {
        try {
          final interactions = await _firestoreService.getInteractions(
            user.uid,
          );
          if (!mounted) return;
          setState(() {
            _adminInteractions = interactions;
          });
          debugPrint('Loaded ${interactions.length} interactions');
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _interactionError =
                e.toString().contains('The query requires an index')
                    ? 'Failed to load activities: Index required. Check Firebase Console.'
                    : 'Failed to load activities: $e';
            _adminInteractions = [];
          });
          debugPrint('Interaction loading error: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load dashboard: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(color: const Color(0xFFFF6949)),
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

  void _showAccountDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminSettingsPage()),
    );
  }

  void _showFullActivityDetails(Interaction interaction) {
    if (!mounted) return;
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
                      top: Radius.circular(16),
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
                      padding: const EdgeInsets.all(16),
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
                          Center(
                            child: Text(
                              'Activity Details',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDetailRow(
                            'Action',
                            _getActionDescription(interaction),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Timestamp',
                            DateFormat(
                              'MMM dd, yyyy HH:mm',
                            ).format(interaction.timestamp.toDate()),
                          ),
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

  List<Map<String, dynamic>> _filteredUsers() {
    return _searchQuery.isEmpty
        ? _activeUsers
            .where(
              (user) => ['student', 'admin', 'lecturer'].contains(user['role']),
            )
            .toList()
        : _activeUsers
            .where(
              (user) =>
                  ['student', 'admin', 'lecturer'].contains(user['role']) &&
                  (user['email']?.toLowerCase().contains(_searchQuery) ??
                      false),
            )
            .toList();
  }

  List<BarChartGroupData> _createUserRegistrationChartData() {
    final Map<String, int> userCounts = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: i)));
      userCounts[date] = 0;
    }
    for (var user in _activeUsers) {
      final timestamp = user['createdAt'] as Timestamp?;
      final date = timestamp?.toDate().toString().split(' ')[0];
      if (date != null && userCounts.containsKey(date)) {
        userCounts[date] = userCounts[date]! + 1;
      }
    }
    final List<BarChartGroupData> barGroups = [];
    userCounts.entries.toList().asMap().forEach((index, entry) {
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

  IconData _getActionIcon(String action) {
    const actionIcons = {
      'create_lecturer': Icons.person_add,
      'create_admin': Icons.admin_panel_settings,
      'delete_user': Icons.delete,
      'suspend_user': Icons.block,
      'unsuspend_user': Icons.check_circle,
      'create_course': Icons.book,
      'upload_material': Icons.upload_file,
    };
    return actionIcons[action] ?? Icons.event;
  }

  String _getActionDescription(Interaction interaction) {
    final adminEmail = interaction.adminName ?? 'Unknown Admin';
    final action = interaction.action;
    final targetEmail = interaction.targetName ?? 'Unknown User';

    const actionDescriptions = {
      'create_lecturer': 'created lecturer account for',
      'create_admin': 'created admin account for',
      'delete_user': 'deleted user',
      'suspend_user': 'suspended user',
      'unsuspend_user': 'unsuspended user',
      'create_course': 'created course',
      'upload_material': 'uploaded material for',
    };

    final description = actionDescriptions[action];
    if (description != null && action.contains('user')) {
      return '$adminEmail $description $targetEmail';
    } else if (description != null) {
      return '$adminEmail $description ${interaction.details ?? targetEmail}';
    }
    return interaction.details ?? 'Performed an action';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final filteredUsers = _filteredUsers();
    final chartLabels = _getChartLabels();

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
                        'Admin Dashboard',
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
                        onPressed: _loadData,
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
                          'Monitor and manage platform activity',
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
                        LayoutBuilder(
                          builder:
                              (context, constraints) => GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: isMobile ? 1 : 2,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                childAspectRatio:
                                    isMobile
                                        ? constraints.maxWidth / 400
                                        : constraints.maxWidth / 800,
                                children: [
                                  _buildActiveUsersCard(
                                    context,
                                    isMobile,
                                    filteredUsers,
                                  ),
                                  _buildRecentActivitiesCard(context, isMobile),
                                ],
                              ),
                        ),
                        const SizedBox(height: 24),
                        _buildUserRegistrationCard(
                          context,
                          isMobile,
                          chartLabels,
                        ),
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
        onTap: _showAccountDetails,
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
                      'Welcome, ${_userName ?? 'Admin'}!',
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

  Widget _buildSearchCard(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by email...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[500],
            fontSize: isMobile ? 14 : 16,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6949)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
        style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
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
          'Active Users',
          _activeUserCount,
          Icons.people,
          context,
          isMobile,
          gradient: [const Color(0xFFFF6949), const Color(0xFFFF8A65)],
        ),
        _buildStatCard(
          'Online Users',
          _onlineUserCount,
          Icons.wifi,
          context,
          isMobile,
          gradient: [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
        ),
        _buildStatCard(
          'Growth Rate',
          '${_growthRate.toStringAsFixed(1)}% ($_appStatus)',
          _growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
          context,
          isMobile,
          gradient: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
        ),
      ],
    );
  }

  Widget _buildActiveUsersCard(
    BuildContext context,
    bool isMobile,
    List<Map<String, dynamic>> filteredUsers,
  ) {
    final displayUsers = filteredUsers.toList();

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
                  'Active Users ($_activeUserCount)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchCard(context, isMobile),
            const SizedBox(height: 12),
            if (displayUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No users found',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height:
                    isMobile
                        ? 180
                        : 200, // Constrained height to match activities
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: displayUsers.length,
                  itemBuilder:
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _buildUserCard(displayUsers[index], isMobile),
                      ),
                ),
              ),
            const SizedBox(height: 16),
            if (filteredUsers.length > 4)
              Center(
                child: TextButton(
                  onPressed:
                      () => Navigator.pushNamed(context, Routes.userManagement),
                  child: Text(
                    'View All Users',
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

  Widget _buildUserCard(Map<String, dynamic> user, bool isMobile) {
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
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: isMobile ? 20 : 22,
            backgroundColor: const Color(0xFFFF6949),
            child: Text(
              (user['email'] as String?)?.isNotEmpty == true
                  ? (user['email'] as String)[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            (user['email'] as String?) ?? 'No Email',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: isMobile ? 14 : 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Role: ${(user['role'] as String?) ?? 'Unknown'}',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: isMobile ? 12 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  (user['lastActive'] as Timestamp?)?.toDate().isAfter(
                            DateTime.now().subtract(
                              const Duration(minutes: 15),
                            ),
                          ) ==
                          true
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
            ),
            child: Icon(
              (user['lastActive'] as Timestamp?)?.toDate().isAfter(
                        DateTime.now().subtract(const Duration(minutes: 15)),
                      ) ==
                      true
                  ? Icons.circle
                  : Icons.circle_outlined,
              color:
                  (user['lastActive'] as Timestamp?)?.toDate().isAfter(
                            DateTime.now().subtract(
                              const Duration(minutes: 15),
                            ),
                          ) ==
                          true
                      ? Colors.green
                      : Colors.grey,
              size: 12,
            ),
          ),
        ),
      ),
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
          'Quick access to common administrative tasks',
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
              label: 'Create Lecturer',
              icon: Icons.person_add,
              route: Routes.createLecturer,
              isMobile: isMobile,
            ),
            _buildActionButton(
              context,
              label: 'Create Admin',
              icon: Icons.admin_panel_settings,
              route: Routes.createAdmin,
              isMobile: isMobile,
            ),
            _buildActionButton(
              context,
              label: 'Manage Users',
              icon: Icons.group,
              route: Routes.userManagement,
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserRegistrationCard(
    BuildContext context,
    bool isMobile,
    List<String> chartLabels,
  ) {
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
                  'New Users (Last 7 Days)',
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
                  onPressed: _loadData,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: isMobile ? 180 : 220,
              child:
                  _createUserRegistrationChartData().isEmpty
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
                          barGroups: _createUserRegistrationChartData(),
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
                                  return index < chartLabels.length
                                      ? Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          chartLabels[index],
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
                                    '${rod.toY.toInt()} New Users\n${chartLabels[groupIndex]}',
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
                  'New Users',
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

  Widget _buildRecentActivitiesCard(BuildContext context, bool isMobile) {
    final displayInteractions = _adminInteractions.take(4).toList();

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
                  'Recent Activities',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_interactionError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _interactionError!,
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Retry',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6949),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (displayInteractions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No activities recorded',
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
                  itemCount: displayInteractions.length,
                  itemBuilder:
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildActivityCard(
                          displayInteractions[index],
                          isMobile,
                        ),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Interaction interaction, bool isMobile) {
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
          onTap: () => _showFullActivityDetails(interaction),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6949).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getActionIcon(interaction.action),
                color: const Color(0xFFFF6949),
                size: isMobile ? 20 : 22,
              ),
            ),
            title: Text(
              _getActionDescription(interaction),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: isMobile ? 12 : 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              DateFormat(
                'MMM dd, HH:mm',
              ).format(interaction.timestamp.toDate()),
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: isMobile ? 11 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFFFF6949),
              size: 20,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
              softWrap: true,
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
        onTap: () => debugPrint('$title tapped'),
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
        alignment: Alignment.center,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 28 : 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: isMobile ? 12 : 14,
            ),
            textAlign: TextAlign.center,
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
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
