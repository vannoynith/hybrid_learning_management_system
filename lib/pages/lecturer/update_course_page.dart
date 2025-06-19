import 'package:flutter/material.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/services/auth_service.dart';
import 'package:hybridlms/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'course_editor.dart';

class UpdateCoursePage extends StatefulWidget {
  final String courseId;

  const UpdateCoursePage({super.key, required this.courseId});

  @override
  _UpdateCoursePageState createState() => _UpdateCoursePageState();
}

class _UpdateCoursePageState extends State<UpdateCoursePage> {
  Course? _course;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCourse();
  }

  Future<void> _fetchCourse() async {
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

      setState(() {
        _course = course;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load course: $e';
        _isLoading = false;
      });
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

      if (user == null) return;

      await firestoreService.updateCourse(user.uid, updatedCourse);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update course: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Course'),
        backgroundColor: const Color(0xFFFF6949),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6949)),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6949),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _course != null
              ? CourseEditor(course: _course!, onSave: _saveCourse)
              : const Center(child: Text('No course data available')),
    );
  }
}
