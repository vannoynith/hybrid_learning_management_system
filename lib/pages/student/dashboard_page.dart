import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/widgets/custom_bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../routes.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../models/course.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  List<Course> courses = [];
  String? courseError;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      courseError = null;
    });
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        userData = await _firestoreService.getUser(user.uid);
        await _loadCourses();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading data: $e', const Color(0xFFEF4444));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadCourses() async {
    try {
      final allCourses = await _firestoreService.getPublishedCourses();
      courses =
          allCourses
              .where((course) => course.id != null && course.id!.isNotEmpty)
              .take(15)
              .toList();
      for (var course in courses) {
        final instructorData = await _firestoreService.getUser(
          course.lecturerId,
        );
        course.lecturerDisplayName =
            instructorData?['displayName']
                ?.toString()
                .split(' ')
                .map(
                  (word) =>
                      word[0].toUpperCase() + word.substring(1).toLowerCase(),
                )
                .join(' ') ??
            'Unknown Instructor';
      }
      if (courses.isEmpty) {
        setState(() {
          courseError = 'No published courses available';
        });
      }
    } catch (e) {
      String errorMessage = 'Failed to load courses: $e';
      if (e.toString().contains('failed-precondition')) {
        RegExp urlRegex = RegExp(r'https?://[^\s]+');
        String? indexUrl = urlRegex.firstMatch(e.toString())?.group(0);
        errorMessage =
            'Failed to load courses: Missing Firestore index. '
            '${indexUrl != null ? 'Create it at $indexUrl' : 'Check Firebase Console.'}';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage =
            'Failed to load courses: Permission denied. '
            'User: ${_authService.getCurrentUser()?.uid}. Check Firestore security rules.';
      }
      if (mounted) {
        setState(() {
          courseError = errorMessage;
        });
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, Routes.profileEdit);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.chat);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Routes.notification);
        break;
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == const Color(0xFFEF4444)
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, Routes.login);
      });
      return const Center(child: CircularProgressIndicator());
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        backgroundColor: const Color(0xFFF7F7F7),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6949), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child:
                        userData?['profileImageUrl'] != null &&
                                userData!['profileImageUrl'].isNotEmpty
                            ? ClipOval(
                              child: Image.network(
                                userData!['profileImageUrl'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color(0xFFFF6949),
                                    ),
                              ),
                            )
                            : const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFFFF6949),
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData?['displayName'] ?? 'User Name',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    userData?['email'] ?? 'user@example.com',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'Dashboard',
              route: Routes.dashboard,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.book,
              title: 'Courses',
              route: Routes.courseList,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Profile',
              route: Routes.profileEdit,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.timeline,
              title: 'Timeline',
              route: Routes.timeline,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.analytics,
              title: 'Analytics',
              route: Routes.analytics,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.assignment,
              title: 'Assignments',
              route: Routes.assignment,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.chat,
              title: 'Chat',
              route: Routes.chat,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.play_circle,
              title: 'Lectures',
              route: Routes.lecture,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'Lecturers',
              route: Routes.lecturers,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              route: Routes.notification,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.quiz,
              title: 'Quizzes',
              route: Routes.quiz,
            ),
            const Divider(color: Color(0xFFE5E7EB)),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onTap: () async {
                await _authService.signOut();
                Navigator.pushReplacementNamed(context, Routes.login);
              },
            ),
          ],
        ),
      ),
      body:
          isLoading
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
                        'Welcome, ${userData?['displayName']?.split(' ')[0] ?? 'User'}',
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
                    leading: Builder(
                      builder:
                          (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Menu',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            style: IconButton.styleFrom(),
                          ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                        onPressed: _loadData,
                        style: IconButton.styleFrom(),
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
                        Text(
                          'Recommended Courses for You',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: isMobile ? 310 : 360,
                          child: Center(
                            child: Text(
                              'Recommended courses to be implemented',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Explore Courses',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (courseError != null)
                          Column(
                            children: [
                              Text(
                                courseError!,
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadCourses,
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
                            ],
                          )
                        else if (courses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No courses available',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: isMobile ? 310 : 360,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: courses.length,
                              itemBuilder: (context, index) {
                                final course = courses[index];
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    14,
                                    8,
                                  ),
                                  child: SizedBox(
                                    width: isMobile ? 300 : 450,
                                    child: CustomCard(
                                      course: course,
                                      instructorName:
                                          course.lecturerDisplayName,
                                      onTap: () {
                                        if (course.id != null &&
                                            course.id!.isNotEmpty) {
                                          Navigator.pushNamed(
                                            context,
                                            Routes.courseDetail,
                                            arguments: {'courseId': course.id},
                                          );
                                        } else {
                                          _showSnackBar(
                                            'Course ID is invalid or missing',
                                            const Color(0xFFEF4444),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'View All Courses',
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.courseList);
                          },
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
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF6949)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
