import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/services/auth_service.dart';
import 'package:hybridlms/services/firestore_service.dart';
import 'package:hybridlms/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'course_editor.dart';

class UpdateCoursePage extends StatefulWidget {
  final String courseId;

  const UpdateCoursePage({super.key, required this.courseId});

  @override
  _UpdateCoursePageState createState() => _UpdateCoursePageState();
}

class _UpdateCoursePageState extends State<UpdateCoursePage>
    with TickerProviderStateMixin {
  Course? _course;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
    _fetchCourse();
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.stop();
      }
    });
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      final course = await firestoreService.getCourse(widget.courseId);
      if (course == null) {
        throw Exception('Course not found');
      }
      if (course.lecturerId != user.uid) {
        throw Exception(
          'Unauthorized: You are not the lecturer of this course',
        );
      }

      // Enhanced debug logging to verify subcollections
      print('Fetched course: ${course.toMap()}');
      print('Fetched modules: ${course.modules}');
      if (course.modules != null) {
        for (var module in course.modules!) {
          print('Module: ${module['name']}, Lessons: ${module['lessons']}');
          if (module['lessons'] != null) {
            for (var lesson in module['lessons']) {
              print(
                'Lesson: ${lesson['name']}, Documents: ${lesson['documents']}',
              );
            }
          }
        }
      } else {
        print('No modules found for course ID: ${widget.courseId}');
      }

      if (mounted) {
        setState(() {
          _course = course;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load course: $e';
          _isLoading = false;
        });
        print('Error fetching course: $e');
      }
    }
  }

  Future<void> _saveCourse(Course updatedCourse) async {
    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update the course with subcollections
      await firestoreService.updateCourse(user.uid, updatedCourse);
      if (updatedCourse.modules != null) {
        await firestoreService.saveCourseSubcollections(
          updatedCourse.id,
          updatedCourse.modules!,
        );
      } else {
        print('No modules to save for course ID: ${updatedCourse.id}');
      }

      if (mounted) {
        _animationController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Course updated successfully',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Failed to update course: $e',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        print('Error updating course: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? const LoadingIndicator()
              : _errorMessage != null
              ? FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: isMobile ? 14 : 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchCourse,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6949),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : _course != null
              ? CourseEditor(course: _course!, onSave: _saveCourse)
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Text(
                    'No course data available',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              ),
    );
  }
}
