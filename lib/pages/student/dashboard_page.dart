// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../../services/auth_service.dart';
// import '../../services/firestore_service.dart';
// import '../../services/recommendation_service.dart';
// import '../../models/course.dart';
// import '../../widgets/course_card.dart';
// import '../../routes.dart';
// import '../../widgets/loading_indicator.dart';
// import '../../widgets/custom_button.dart';

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   List<Course> recommendedCourses = [];
//   bool isLoading = true;
//   Map<String, dynamic>? userData;
//   final RecommendationService _recommendationService = RecommendationService();
//   final AuthService _authService = AuthService();
//   final FirestoreService _firestoreService = FirestoreService();
//   int _selectedIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => isLoading = true);
//     try {
//       final user = _authService.getCurrentUser();
//       if (user != null) {
//         recommendedCourses = await _recommendationService.getRecommendations(
//           user.uid,
//         );
//         userData = await _firestoreService.getUser(user.uid);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error loading data: $e'),
//           backgroundColor: const Color(0xFFEF4444),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _onNavItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//     if (index == 1) {
//       Navigator.pushNamed(context, Routes.profile);
//     } else if (index == 2) {
//       Navigator.pushNamed(context, Routes.chat);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = _authService.getCurrentUser();
//     final firstLetter =
//         userData?['displayName']?.isNotEmpty == true
//             ? userData!['displayName'][0].toUpperCase()
//             : 'U';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Welcome, ${userData?['displayName']?.split(' ')[0] ?? 'User'}',
//         ),
//         leading: Builder(
//           builder:
//               (context) => IconButton(
//                 icon: CircleAvatar(
//                   radius: 18,
//                   backgroundColor: const Color.fromARGB(255, 138, 138, 138),
//                   child: Text(
//                     firstLetter,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//         ),
//       ),
//       drawer: Drawer(
//         backgroundColor: const Color(0xFFF7F7F7),
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFFF6949), Color(0xFFFF6949)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   const CircleAvatar(
//                     radius: 40,
//                     backgroundColor: Colors.white,
//                     child: Icon(
//                       Icons.person,
//                       size: 50,
//                       color: Color(0xFFFF6949),
//                     ),
//                   ),
//                   Text(
//                     userData?['displayName'] ?? 'User Name',
//                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     textAlign: TextAlign.center,
//                   ),
//                   Text(
//                     userData?['email'] ?? 'user@example.com',
//                     style: Theme.of(
//                       context,
//                     ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.home,
//               title: 'Dashboard',
//               route: Routes.dashboard,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.book,
//               title: 'Courses',
//               route: Routes.courseList,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.person,
//               title: 'Profile',
//               route: Routes.profile,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.timeline,
//               title: 'Timeline',
//               route: Routes.timeline,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.analytics,
//               title: 'Analytics',
//               route: Routes.analytics,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.assignment,
//               title: 'Assignments',
//               route: Routes.assignment,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.chat,
//               title: 'Chat',
//               route: Routes.chat,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.play_circle,
//               title: 'Lectures',
//               route: Routes.lecture,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.people,
//               title: 'Lecturers',
//               route: Routes.lecturers,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.notifications,
//               title: 'Notifications',
//               route: Routes.notification,
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.quiz,
//               title: 'Quizzes',
//               route: Routes.quiz,
//             ),
//             const Divider(color: Color(0xFFE5E7EB)),
//             ListTile(
//               leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
//               title: const Text(
//                 'Logout',
//                 style: TextStyle(color: Color(0xFFEF4444)),
//               ),
//               onTap: () async {
//                 await _authService.signOut();
//                 Navigator.pushReplacementNamed(context, Routes.login);
//               },
//             ),
//           ],
//         ),
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return isLoading
//               ? const LoadingIndicator()
//               : SingleChildScrollView(
//                 padding: EdgeInsets.all(constraints.maxWidth * 0.05),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Recommended for you',
//                       style: Theme.of(context).textTheme.headlineMedium,
//                     ),
//                     SizedBox(height: constraints.maxHeight * 0.02),
//                     recommendedCourses.isEmpty
//                         ? const Center(
//                           child: Text('No recommendations available.'),
//                         )
//                         : ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: recommendedCourses.length,
//                           itemBuilder: (context, index) {
//                             final course = recommendedCourses[index];
//                             return Padding(
//                               padding: const EdgeInsets.only(bottom: 12.0),
//                               child: CourseCard(
//                                 course: course,
//                                 onTap: () {
//                                   Navigator.pushNamed(
//                                     context,
//                                     Routes.courseDetail,
//                                     arguments: {'courseId': course.id},
//                                   );
//                                 },
//                               ),
//                             );
//                           },
//                         ),
//                     SizedBox(height: constraints.maxHeight * 0.03),
//                     CustomButton(
//                       text: 'View All Courses',
//                       onPressed: () {
//                         Navigator.pushNamed(context, Routes.courseList);
//                       },
//                     ),
//                   ],
//                 ),
//               );
//         },
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [const Color(0xFFFF6949), const Color(0xFFFF6949)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildNavItem(icon: Icons.home, label: 'Home', index: 0),
//                 _buildNavItem(icon: Icons.person, label: 'Profile', index: 1),
//                 _buildNavItem(icon: Icons.chat, label: 'Chat', index: 2),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem({
//     required IconData icon,
//     required String label,
//     required int index,
//   }) {
//     final isSelected = _selectedIndex == index;
//     return GestureDetector(
//       onTap: () => _onNavItemTapped(index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOutBack,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AnimatedScale(
//               scale: isSelected ? 1.2 : 1.0,
//               duration: const Duration(milliseconds: 300),
//               child: Icon(
//                 icon,
//                 size: 28,
//                 color:
//                     isSelected
//                         ? const Color.fromARGB(255, 255, 255, 255)
//                         : const Color.fromARGB(255, 255, 185, 149),
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : Colors.white70,
//                 fontSize: 12,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String route,
//   }) {
//     return AnimatedOpacity(
//       opacity: 1.0,
//       duration: const Duration(milliseconds: 300),
//       child: ListTile(
//         leading: Icon(icon, color: const Color(0xFFFF6949)),
//         title: Text(
//           title,
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//             color: const Color.fromARGB(255, 0, 0, 0),
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         onTap: () {
//           Navigator.pop(context);
//           Navigator.pushNamed(context, route);
//         },
//       ),
//     );
//   }
// }
