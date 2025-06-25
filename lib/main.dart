import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:hybridlms/pages/admin/admin_settings_page.dart';
import 'package:hybridlms/pages/admin/change_password_for_admin_page.dart';
import 'package:hybridlms/pages/admin/create_admin_page.dart';
import 'package:hybridlms/pages/admin/create_lecturer_page.dart';
import 'package:hybridlms/pages/admin/user_management_page.dart';
import 'package:hybridlms/pages/lecturer/change_password_for_lecturer_page.dart';
import 'package:hybridlms/pages/lecturer/content_viewer_page.dart';
import 'package:hybridlms/pages/lecturer/course_editor.dart';
import 'package:hybridlms/pages/lecturer/course_management_page.dart';
import 'package:hybridlms/pages/lecturer/create_class_token_page.dart';
import 'package:hybridlms/pages/lecturer/file_preview_page.dart';
import 'package:hybridlms/pages/lecturer/lecturer_dashboard.dart';
import 'package:hybridlms/pages/lecturer/lecturer_settings_page.dart';
import 'package:hybridlms/pages/lecturer/update_course_page.dart';
import 'package:hybridlms/pages/student/change_password_page.dart';
import 'package:hybridlms/pages/student/course_detail_page.dart';
import 'package:hybridlms/pages/student/dashboard_page.dart';
import 'package:hybridlms/pages/student/profile_edit_page.dart';
import 'package:hybridlms/routes.dart';
import 'package:hybridlms/theme.dart';
import 'package:hybridlms/pages/signup_page.dart';
import 'package:hybridlms/pages/login_page.dart';
import 'package:hybridlms/pages/student/analytics_page.dart';
import 'package:hybridlms/pages/student/assignment_page.dart';
import 'package:hybridlms/pages/chat_page.dart';
import 'package:hybridlms/pages/admin/admin_dashboard_page.dart';
import 'package:hybridlms/services/auth_service.dart';
import 'package:hybridlms/services/firestore_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'AI HLMS',
        theme: appTheme(),
        initialRoute: Routes.login,
        routes: {
          //login and signup
          Routes.login:
              (context) => const FadeTransitionPage(child: LoginPage()),
          Routes.signup:
              (context) => const FadeTransitionPage(child: SignupPage()),

          //student
          Routes.dashboard:
              (context) => const FadeTransitionPage(child: DashboardPage()),
          Routes.profileEdit:
              (context) => const FadeTransitionPage(child: ProfileEditPage()),
          Routes.changePassword:
              (context) => const FadeTransitionPage(
                child: ChangePasswordForStudentPage(),
              ),
          Routes.courseDetail:
              (context) => FadeTransitionPage(
                child: CourseDetailPage(
                  arguments:
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>?,
                ),
              ),
          // Routes.analytics:
          //     (context) => const FadeTransitionPage(child: AnalyticsPage()),
          // Routes.assignment:
          //     (context) => const FadeTransitionPage(child: AssignmentPage()),
          // Routes.chat: (context) => const FadeTransitionPage(child: ChatPage()),

          //admin
          Routes.adminDashboard:
              (context) =>
                  const FadeTransitionPage(child: AdminDashboardPage()),
          Routes.createAdmin:
              (context) => const FadeTransitionPage(child: CreateAdminPage()),
          Routes.createLecturer:
              (context) =>
                  const FadeTransitionPage(child: CreateLecturerPage()),
          Routes.userManagement:
              (context) =>
                  const FadeTransitionPage(child: UserManagementPage()),
          Routes.adminSetting:
              (context) => const FadeTransitionPage(child: AdminSettingsPage()),
          Routes.changePasswordForAdmin:
              (context) =>
                  const FadeTransitionPage(child: ChangePasswordForAdminPage()),

          //lecturer
          Routes.lecturerDashboard:
              (context) => const FadeTransitionPage(child: LecturerDashboard()),
          Routes.courseManagement:
              (context) =>
                  const FadeTransitionPage(child: CourseManagementPage()),
          Routes.contentViewPage:
              (context) => const FadeTransitionPage(child: ContentViewerPage()),
          Routes.courseEditor:
              (context) => const FadeTransitionPage(child: CourseEditor()),
          Routes.updateCourse:
              (context) => UpdateCoursePage(
                courseId: ModalRoute.of(context)!.settings.arguments as String,
              ),
          Routes.lecturerSettingsPage:
              (context) =>
                  const FadeTransitionPage(child: LecturerSettingsPage()),
          Routes.changePasswordForLecturer:
              (context) => const FadeTransitionPage(
                child: ChangePasswordForLecturerPage(),
              ),
          Routes.filePreviewPage:
              (context) => const FadeTransitionPage(child: FilePreviewPage()),
          Routes.createClassToken:
              (context) =>
                  const FadeTransitionPage(child: CreateClassTokenPage()),
        },
      ),
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
  void didUpdateWidget(covariant FadeTransitionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      _controller.reset();
      _controller.forward();
    }
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
