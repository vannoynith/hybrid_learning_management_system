import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/pages/lecturer/create_course_page.dart';
import 'package:hybridlms/pages/lecturer/lecturer_settings_page.dart';
import 'package:hybridlms/pages/lecturer/manage_course_page.dart';
import 'routes.dart';
import 'pages/signup_page.dart';
import 'theme.dart';
import 'pages/login_page.dart';
//import 'pages/student/dashboard_page.dart';
//import 'pages/student/profile_page.dart';
//import 'pages/timeline_page.dart';
import 'pages/student/analytics_page.dart';
import 'pages/student/assignment_page.dart';
import 'pages/chat_page.dart';
//import 'pages/notification_page.dart';
//import 'pages/student/quiz_page.dart';
//import 'pages/student/lecturers_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/lecturer/lecturer_dashboard_page.dart';
//import 'pages/student/profile_edit_page.dart';
import 'pages/admin/create_admin_page.dart';
import 'pages/admin/create_lecturer_page.dart';
import 'pages/admin/user_management_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI HLMS',
      theme: appTheme(),
      initialRoute: Routes.login,
      routes: {
        Routes.login: (context) => const FadeTransitionPage(child: LoginPage()),
        Routes.signup:
            (context) => const FadeTransitionPage(child: SignupPage()),
        // Routes.dashboard:
        //     (context) => const FadeTransitionPage(child: DashboardPage()),
        // Routes.courseList:
        //     (context) => const FadeTransitionPage(child: CourseListPage()),
        // Routes.courseDetail: (context) {
        //   final args =
        //       ModalRoute.of(context)?.settings.arguments
        //           as Map<String, dynamic>?;
        //   final courseId = args?['courseId'] as String? ?? '';
        //   return FadeTransitionPage(
        //     child: CourseDetailPage(courseId: courseId),
        //   );
        // },
        // Routes.profile:
        //     (context) => const FadeTransitionPage(child: ProfilePage()),
        // // Routes.timeline: (context) =>
        // //const FadeTransitionPage(child: TimelinePage()),
        Routes.analytics:
            (context) => const FadeTransitionPage(child: AnalyticsPage()),
        Routes.assignment:
            (context) => const FadeTransitionPage(child: AssignmentPage()),
        Routes.chat: (context) => const FadeTransitionPage(child: ChatPage()),
        // Routes.lecture:
        //     (context) => const FadeTransitionPage(child: LecturePage()),
        // Routes.lecturers:
        //     (context) => const FadeTransitionPage(child: LecturersPage()),
        // Routes.notification:
        //     (context) => const FadeTransitionPage(child: NotificationPage()),
        // Routes.quiz: (context) => const FadeTransitionPage(child: QuizPage()),
        // Routes.profileEdit:
        //     (context) => const FadeTransitionPage(child: ProfileEditPage()),
        Routes.adminDashboard:
            (context) => const FadeTransitionPage(child: AdminDashboardPage()),
        Routes.lecturerDashboard:
            (context) =>
                const FadeTransitionPage(child: LecturerDashboardPage()),
        Routes.createAdmin:
            (context) => const FadeTransitionPage(child: CreateAdminPage()),
        Routes.createLecturer:
            (context) => const FadeTransitionPage(child: CreateLecturerPage()),
        Routes.userManagement:
            (context) => const FadeTransitionPage(child: UserManagementPage()),
        Routes.createCourse:
            (context) => const FadeTransitionPage(child: CreateCoursePage()),
        Routes.manageCourse: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Course?;
          if (args == null) {
            return const FadeTransitionPage(
              child: Scaffold(body: Center(child: Text('No course provided'))),
            );
          }
          return FadeTransitionPage(child: ManageCoursePage(course: args));
        },
        Routes.lecturerSettings:
            (context) =>
                const FadeTransitionPage(child: LecturerSettingsPage()),
      },
    );
  }
}

class FadeTransitionPage extends StatefulWidget {
  final Widget child;

  const FadeTransitionPage({super.key, required this.child});

  @override
  State<FadeTransitionPage> createState() => _FadeTransitionPageState();
}

class _FadeTransitionPageState extends State<FadeTransitionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
