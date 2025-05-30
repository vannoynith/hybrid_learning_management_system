import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../routes.dart';
import '../../models/interaction.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

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
    setState(() {
      _isLoading = true;
      _interactionError = null;
    });
    try {
      _activeUsers = await _firestoreService.getActiveUsers(
        roles: ['lecturer', 'student'],
      );
      _activeUserCount = _activeUsers.length;

      final now = DateTime.now();
      _onlineUserCount =
          _activeUsers.where((user) {
            final lastActive = user['lastActive']?.toDate() as DateTime?;
            return lastActive != null &&
                lastActive.isAfter(now.subtract(const Duration(minutes: 15)));
          }).length;

      final newUsers =
          _activeUsers.where((user) {
            final timestamp = user['createdAt']?.toDate() as DateTime?;
            return timestamp != null &&
                timestamp.isAfter(now.subtract(const Duration(days: 30)));
          }).length;
      _growthRate =
          (_activeUsers.isNotEmpty ? newUsers / _activeUsers.length : 0) * 100;

      if (_growthRate > 5) {
        _appStatus = 'Growing';
      } else if (_growthRate < -2) {
        _appStatus = 'Declining';
      } else {
        _appStatus = 'Stable';
      }

      final currentUser = _authService.getCurrentUser();
      debugPrint('Current user: ${currentUser?.uid}');
      if (currentUser != null) {
        final userData = await _firestoreService.getUser(currentUser.uid);
        debugPrint('User data: $userData');
        if (userData == null || userData['role'] != 'admin') {
          setState(() {
            _interactionError = 'User is not an admin or user data not found';
          });
          _adminInteractions = [];
        } else {
          try {
            _adminInteractions = await _firestoreService.getInteractions(
              currentUser.uid,
            );
            debugPrint('Loaded ${_adminInteractions.length} interactions');
          } catch (e) {
            setState(() {
              String errorMessage = e.toString();
              if (errorMessage.contains('The query requires an index')) {
                errorMessage =
                    'Failed to load admin activities: The query requires an index. '
                    'Create it here: https://console.firebase.google.com/v1/r/project/al-learn-db/firestore/indexes?create_composite=CIBwcm9qZWN0cy9haS1sZWFybl1kYi9kYXRhYmFzZXMVKG RIZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvaW50ZXJhY3Rpb25zL2luZGV4ZXMvXxABGgoKBnVzZXJ JZBABGg0KCXRpbWVzdGFtcBACGgwKCF9fbmFtZ VOFEAI';
              } else {
                errorMessage = 'Failed to load admin activities: $e';
              }
              _interactionError = errorMessage;
            });
            _adminInteractions = [];
            debugPrint('Interaction loading error: $e');
          }
        }
      } else {
        setState(() {
          _interactionError = 'No user logged in to load admin activities';
        });
        _adminInteractions = [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log out: $e')));
      }
    }
  }

  void _showAccountDetails() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user logged in')));
      return;
    }

    try {
      final userData = await _firestoreService.getUser(currentUser.uid);
      if (userData == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User data not found')));
        return;
      }

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Account Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${userData['email'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Username: ${userData['username'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Role: ${userData['role'] ?? 'N/A'}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load account details: $e')),
      );
    }
  }

  void _showFullActivityDetails(Interaction interaction) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Activity Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActionDescription(interaction),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Timestamp: ${interaction.timestamp.toDate()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  List<Map<String, dynamic>> _filteredUsers() {
    if (_searchQuery.isEmpty) {
      return _activeUsers;
    }
    return _activeUsers
        .where(
          (user) =>
              (user['email']?.toLowerCase().contains(_searchQuery) ?? false),
        )
        .toList();
  }

  List<BarChartGroupData> _createUserRegistrationChartData() {
    final Map<String, int> userCounts = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i)).toString().split(' ')[0];
      userCounts[date] = 0;
    }
    for (var user in _activeUsers) {
      final date = user['createdAt']?.toDate().toString().split(' ')[0];
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
              color: Colors.blueAccent,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
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

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create_lecturer':
        return Icons.person_add;
      case 'create_admin':
        return Icons.admin_panel_settings;
      case 'delete_user':
        return Icons.delete;
      case 'suspend_user':
        return Icons.block;
      case 'unsuspend_user':
        return Icons.check_circle;
      case 'create_course':
        return Icons.book;
      case 'upload_material':
        return Icons.upload_file;
      default:
        return Icons.event;
    }
  }

  String _getActionDescription(Interaction interaction) {
    String admin = interaction.adminName ?? 'Unknown Admin';
    String action = interaction.action;
    String target = interaction.targetName ?? 'Unknown User';
    String targetType = 'account';

    switch (action) {
      case 'create_lecturer':
        return 'Admin $admin created lecturer $targetType $target';
      case 'create_admin':
        return 'Admin $admin created admin $targetType $target';
      case 'delete_user':
        return 'Admin $admin deleted $targetType $target';
      case 'suspend_user':
        return 'Admin $admin suspended $targetType $target';
      case 'unsuspend_user':
        return 'Admin $admin unsuspended $targetType $target';
      case 'create_course':
        return 'Admin $admin created a course${interaction.courseId != null ? " (${interaction.courseId})" : ""}';
      case 'upload_material':
        return 'Admin $admin uploaded material${interaction.courseId != null ? " to course ${interaction.courseId}" : ""}';
      default:
        return interaction.details ?? 'Admin $admin performed an action';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers();
    final chartLabels = _getChartLabels();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          semanticsLabel: 'Admin Dashboard',
        ),
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                const Color.fromARGB(255, 248, 138, 11),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Account Details',
            onPressed: _showAccountDetails,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
              ? const LoadingIndicator()
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Search lecturers or students by email...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                title: 'Active Users',
                                count: _activeUserCount,
                                icon: Icons.people,
                                gradient: [Colors.blue, Colors.blueAccent],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                title: 'Online Users',
                                count: _onlineUserCount,
                                icon: Icons.wifi,
                                gradient: [Colors.green, Colors.greenAccent],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                title: 'Growth Rate',
                                count:
                                    '${_growthRate.toStringAsFixed(1)}% ($_appStatus)',
                                icon:
                                    _growthRate >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                gradient:
                                    _growthRate >= 0
                                        ? [Colors.teal, Colors.tealAccent]
                                        : [Colors.red, Colors.redAccent],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Users: $_activeUserCount',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    fontSize:
                                        MediaQuery.of(context).size.width > 600
                                            ? 24
                                            : 20,
                                  ),
                                  semanticsLabel:
                                      'Active Users: $_activeUserCount',
                                ),
                                const SizedBox(height: 16),
                                if (filteredUsers.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Text(
                                      'No lecturers or students found.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredUsers.map(
                                    (user) => ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4,
                                          ),
                                      title: Text(
                                        user['email'] ?? 'No Email',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width >
                                                      600
                                                  ? 16
                                                  : 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Role: ${user['role'] ?? 'Unknown'}',
                                        style: TextStyle(
                                          fontSize:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width >
                                                      600
                                                  ? 14
                                                  : 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Icon(
                                        user['lastActive'] != null &&
                                                (user['lastActive'].toDate()
                                                        as DateTime)
                                                    .isAfter(
                                                      DateTime.now().subtract(
                                                        const Duration(
                                                          minutes: 15,
                                                        ),
                                                      ),
                                                    )
                                            ? Icons.wifi
                                            : Icons.wifi_off,
                                        color:
                                            user['lastActive'] != null &&
                                                    (user['lastActive'].toDate()
                                                            as DateTime)
                                                        .isAfter(
                                                          DateTime.now()
                                                              .subtract(
                                                                const Duration(
                                                                  minutes: 15,
                                                                ),
                                                              ),
                                                        )
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: [
                            _buildActionButton(
                              context,
                              label: 'Create Lecturer',
                              icon: Icons.person_add,
                              route: Routes.createLecturer,
                            ),
                            _buildActionButton(
                              context,
                              label: 'Create Admin',
                              icon: Icons.admin_panel_settings,
                              route: Routes.createAdmin,
                            ),
                            _buildActionButton(
                              context,
                              label: 'Manage Users',
                              icon: Icons.group,
                              route: Routes.userManagement,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Users (Last 7 Days)',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    fontSize:
                                        MediaQuery.of(context).size.width > 600
                                            ? 24
                                            : 20,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      barGroups:
                                          _createUserRegistrationChartData(),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() <
                                                  chartLabels.length) {
                                                return Text(
                                                  chartLabels[value.toInt()],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      gridData: const FlGridData(show: false),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem: (
                                            group,
                                            groupIndex,
                                            rod,
                                            rodIndex,
                                          ) {
                                            return BarTooltipItem(
                                              rod.toY.toInt().toString(),
                                              const TextStyle(
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Admin Activities',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    fontSize:
                                        MediaQuery.of(context).size.width > 600
                                            ? 24
                                            : 20,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_interactionError != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _interactionError!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () async {
                                            setState(() => _isLoading = true);
                                            await Future.delayed(
                                              const Duration(seconds: 5),
                                            );
                                            await _loadData();
                                          },
                                          child: const Text(
                                            'Retry After Index Creation',
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (_adminInteractions.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Text(
                                      'No admin activities recorded yet.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height:
                                        300, // Fixed height for scrollable area
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children:
                                            _adminInteractions
                                                .take(50)
                                                .map(
                                                  (
                                                    interaction,
                                                  ) => GestureDetector(
                                                    onLongPress:
                                                        () =>
                                                            _showFullActivityDetails(
                                                              interaction,
                                                            ),
                                                    child: ListTile(
                                                      dense: true,
                                                      leading: Icon(
                                                        _getActionIcon(
                                                          interaction.action,
                                                        ),
                                                        color:
                                                            Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                      ),
                                                      title: Text(
                                                        _getActionDescription(
                                                          interaction,
                                                        ),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize:
                                                              MediaQuery.of(
                                                                        context,
                                                                      ).size.width >
                                                                      600
                                                                  ? 15
                                                                  : 13,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      subtitle: Text(
                                                        interaction.timestamp
                                                            .toDate()
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize:
                                                              MediaQuery.of(
                                                                        context,
                                                                      ).size.width >
                                                                      600
                                                                  ? 13
                                                                  : 11,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Copyright © 2025',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required dynamic count,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              count is String ? count : count.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String route,
  }) {
    return Builder(
      builder: (BuildContext buttonContext) {
        return ElevatedButton.icon(
          onPressed: () async {
            debugPrint('Button pressed: $label, navigating to $route');
            try {
              // Check if the route exists in the Navigator's route table
              if (Navigator.of(buttonContext).canPop() ||
                  ModalRoute.of(buttonContext)?.settings.name != route) {
                await Navigator.pushNamed(buttonContext, route);
                debugPrint('Successfully navigated to $route');
              } else {
                debugPrint('Route $route is already the current route');
                ScaffoldMessenger.of(buttonContext).showSnackBar(
                  SnackBar(content: Text('Already on $label page')),
                );
              }
            } catch (e) {
              debugPrint('Navigation error for route $route: $e');
              ScaffoldMessenger.of(buttonContext).showSnackBar(
                SnackBar(content: Text('Failed to navigate to $label: $e')),
              );
            }
          },
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(140, 48),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
