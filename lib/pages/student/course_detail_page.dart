import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/course.dart';
import '../../routes.dart';
import '../../widgets/loading_indicator.dart';

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CourseDetailPage({super.key, this.arguments});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  bool isLoading = true;
  Course? course;
  bool isEnrolled = false;
  double? userRating;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _tokenController = TextEditingController();
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print('CourseDetailPage initialized with arguments: ${widget.arguments}');
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() => isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          errorMessage = 'User not authenticated. Please log in.';
        });
        return;
      }

      if (widget.arguments == null || widget.arguments!['courseId'] == null) {
        setState(() {
          errorMessage = 'No course ID provided.';
        });
        return;
      }

      final courseId = widget.arguments!['courseId'] as String;
      if (courseId.isEmpty) {
        setState(() {
          errorMessage = 'Course ID is empty.';
        });
        return;
      }

      print('Loading course with ID: $courseId for user: ${user.uid}');
      course = await _firestoreService.getCourse(courseId);
      if (course == null) {
        setState(() {
          errorMessage = 'Course not found for ID: $courseId';
        });
        return;
      }

      // Fetch lecturer name if not set
      if (course!.lecturerDisplayName.isEmpty) {
        final instructorData = await _firestoreService.getUser(
          course!.lecturerId,
        );
        course!.lecturerDisplayName =
            instructorData?['displayName']
                ?.toString()
                .split(' ')
                .map(
                  (word) =>
                      word.isNotEmpty
                          ? word[0].toUpperCase() +
                              word.substring(1).toLowerCase()
                          : '',
                )
                .join(' ') ??
            'Unknown Instructor';
      }

      final enrollments = await _firestoreService.getEnrolledStudents(courseId);
      isEnrolled = enrollments.any((e) => e['uid'] == user.uid);

      // Fetch instructor names for lessons
      for (var module in course!.modules ?? []) {
        for (var lesson in module['lessons'] ?? []) {
          final lecturerId = lesson['lecturerId'] as String?;
          if (lecturerId != null && lesson['instructorName'] == null) {
            final instructorData = await _firestoreService.getUser(lecturerId);
            lesson['instructorName'] =
                instructorData?['displayName'] ?? 'Unknown Instructor';
          }
        }
      }
    } catch (e) {
      setState(() {
        errorMessage =
            e.toString().contains('failed-precondition')
                ? 'Missing Firestore index. Check Firebase Console.'
                : e.toString().contains('permission-denied')
                ? 'Permission denied. Contact support.'
                : 'Error loading course: $e';
      });
      print('Error loading course: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _enrollWithToken() async {
    setState(() => isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null || course == null) {
        setState(() {
          errorMessage = 'User or course not available.';
        });
        return;
      }

      const validToken = 'COURSE123'; // Replace with backend validation
      if (_tokenController.text.trim() == validToken) {
        await _firestoreService.enrollStudent(course!.id, user.uid);
        setState(() {
          isEnrolled = true;
          errorMessage = null;
          _tokenController.clear();
        });
        _showSnackBar('Successfully enrolled!', Colors.green);
      } else {
        setState(() {
          errorMessage = 'Invalid token. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Enrollment failed: $e';
      });
      _showSnackBar('Enrollment failed: $e', const Color(0xFFEF4444));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitRating(double rating) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null || course == null) return;
      await _firestoreService.updateCourseRating(course!.id, user.uid, rating);
      setState(() {
        userRating = rating;
      });
      _showSnackBar('Rating submitted: $rating', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to submit rating: $e', const Color(0xFFEF4444));
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          isLoading
              ? const Center(child: LoadingIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: isMobile ? 200 : 300,
                    floating: false,
                    pinned: true,
                    toolbarHeight: 60,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        course?.title ?? 'Course Detail',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      background:
                          course?.thumbnailUrl != null
                              ? Image.network(
                                course!.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    ),
                              )
                              : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF6949),
                                      Color(0xFFFF8A65),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                    ),
                    backgroundColor: const Color(0xFFFF6949),
                    elevation: 0,
                    actions: [
                      if (isEnrolled && course != null)
                        IconButton(
                          icon: const Icon(Icons.star, color: Colors.white),
                          tooltip: 'Rate Course',
                          onPressed: () => _showRatingDialog(),
                        ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child:
                        course == null
                            ? Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    errorMessage ?? 'Course not found',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 16 : 18,
                                      color: Colors.redAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.pushReplacementNamed(
                                          context,
                                          Routes.dashboard,
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6949),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Back to Dashboard',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: ElevatedButton.icon(
                                        onPressed: _loadCourseData,
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          'Retry',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFF6949,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course!.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 20 : 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Instructor: ${course!.lecturerDisplayName}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Rating: ${course!.rating?.toStringAsFixed(1) ?? 'N/A'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: isMobile ? 14 : 16,
                                              color: Colors.amber,
                                            ),
                                          ),
                                          if (userRating != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Text(
                                                '(Your rating: $userRating)',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isMobile ? 12 : 14,
                                                  color: Colors.black54,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Category: ${course!.category ?? 'N/A'}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Enrolled: ${course!.enrolledCount} students',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        course!.description.isNotEmpty
                                            ? course!.description
                                            : 'No description available.',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 16,
                                          color: Colors.black45,
                                        ),
                                        textAlign: TextAlign.justify,
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Modules',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...?course!.modules?.map(
                                            (module) => Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: ExpansionTile(
                                                title: Text(
                                                  module['name'] ??
                                                      'Unnamed Module',
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        isMobile ? 16 : 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                leading: Icon(
                                                  Icons.book,
                                                  color: const Color(
                                                    0xFFFF6949,
                                                  ),
                                                  size: isMobile ? 24 : 28,
                                                ),
                                                childrenPadding:
                                                    const EdgeInsets.all(8),
                                                tilePadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                backgroundColor: Colors.white,
                                                collapsedBackgroundColor:
                                                    Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                collapsedShape:
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                children: [
                                                  if (module['thumbnailUrl'] !=
                                                      null)
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        module['thumbnailUrl'],
                                                        height:
                                                            isMobile
                                                                ? 100
                                                                : 150,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              height:
                                                                  isMobile
                                                                      ? 100
                                                                      : 150,
                                                              color:
                                                                  Colors
                                                                      .grey[300],
                                                              child: const Icon(
                                                                Icons.error,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  if (module['thumbnailUrl'] !=
                                                      null)
                                                    const SizedBox(height: 8),
                                                  ...?(isEnrolled
                                                      ? module['lessons']
                                                          ?.map<Widget>(
                                                            (
                                                              lesson,
                                                            ) => ListTile(
                                                              contentPadding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                  ),
                                                              leading: const Icon(
                                                                Icons
                                                                    .play_circle_outline,
                                                                color: Color(
                                                                  0xFFFF6949,
                                                                ),
                                                              ),
                                                              title: Text(
                                                                lesson['name'] ??
                                                                    'Unnamed Lesson',
                                                                style: GoogleFonts.poppins(
                                                                  fontSize:
                                                                      isMobile
                                                                          ? 14
                                                                          : 16,
                                                                ),
                                                              ),
                                                              subtitle: Text(
                                                                'Instructor: ${lesson['instructorName'] ?? 'Unknown'}',
                                                                style: GoogleFonts.poppins(
                                                                  fontSize:
                                                                      isMobile
                                                                          ? 12
                                                                          : 14,
                                                                  color:
                                                                      Colors
                                                                          .black54,
                                                                ),
                                                              ),
                                                              trailing: const Icon(
                                                                Icons.lock_open,
                                                                color: Color(
                                                                  0xFFFF6949,
                                                                ),
                                                              ),
                                                              onTap: () {
                                                                final contentUrls = [
                                                                  ...(lesson['documents']
                                                                          as List<
                                                                            dynamic
                                                                          >? ??
                                                                      []),
                                                                  ...(lesson['videos']
                                                                          as List<
                                                                            dynamic
                                                                          >? ??
                                                                      []),
                                                                  ...(lesson['images']
                                                                          as List<
                                                                            dynamic
                                                                          >? ??
                                                                      []),
                                                                ];
                                                                if (contentUrls
                                                                    .isNotEmpty) {
                                                                  Navigator.pushNamed(
                                                                    context,
                                                                    Routes
                                                                        .contentViewPage,
                                                                    arguments: {
                                                                      'fileUrl':
                                                                          contentUrls
                                                                              .first,
                                                                      'lessonName':
                                                                          lesson['name'] ??
                                                                          'Unnamed Lesson',
                                                                    },
                                                                  );
                                                                } else {
                                                                  _showSnackBar(
                                                                    'No content available for this lesson.',
                                                                    const Color(
                                                                      0xFFEF4444,
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          )
                                                          .toList()
                                                      : module['lessons']
                                                          ?.map<Widget>(
                                                            (
                                                              lesson,
                                                            ) => ListTile(
                                                              contentPadding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                  ),
                                                              leading: const Icon(
                                                                Icons
                                                                    .play_circle_outline,
                                                                color: Color(
                                                                  0xFFFF6949,
                                                                ),
                                                              ),
                                                              title: Text(
                                                                lesson['name'] ??
                                                                    'Unnamed Lesson',
                                                                style: GoogleFonts.poppins(
                                                                  fontSize:
                                                                      isMobile
                                                                          ? 14
                                                                          : 16,
                                                                ),
                                                              ),
                                                              subtitle: Text(
                                                                'Instructor: ${lesson['instructorName'] ?? 'Unknown'}',
                                                                style: GoogleFonts.poppins(
                                                                  fontSize:
                                                                      isMobile
                                                                          ? 12
                                                                          : 14,
                                                                  color:
                                                                      Colors
                                                                          .black54,
                                                                ),
                                                              ),
                                                              trailing:
                                                                  const Icon(
                                                                    Icons.lock,
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                              onTap: null,
                                                            ),
                                                          )
                                                          .toList()),
                                                ],
                                              ),
                                            ),
                                          ) ??
                                          [
                                            Text(
                                              'No modules available.',
                                              style: GoogleFonts.poppins(
                                                fontSize: isMobile ? 14 : 16,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                      if (!isEnrolled)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 24,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Enroll in this Course',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isMobile ? 16 : 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: _tokenController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Enter Enrollment Token',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  errorText: errorMessage,
                                                  prefixIcon: const Icon(
                                                    Icons.vpn_key,
                                                    color: Color(0xFFFF6949),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[200]!,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFFFF6949,
                                                              ),
                                                              width: 2,
                                                            ),
                                                      ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide:
                                                        const BorderSide(
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                  ),
                                                  focusedErrorBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color:
                                                                  Colors
                                                                      .redAccent,
                                                              width: 2,
                                                            ),
                                                      ),
                                                  labelStyle:
                                                      GoogleFonts.poppins(
                                                        color: Colors.grey[800],
                                                      ),
                                                ),
                                                onSubmitted:
                                                    (_) => _enrollWithToken(),
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed:
                                                    isLoading
                                                        ? null
                                                        : _enrollWithToken,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFFF6949,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                  minimumSize: const Size(
                                                    double.infinity,
                                                    48,
                                                  ),
                                                ),
                                                child:
                                                    isLoading
                                                        ? const SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child:
                                                              CircularProgressIndicator(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                        : Text(
                                                          'Enroll Now',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                              ),
                                            ],
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

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempRating = userRating ?? 0;
        return AlertDialog(
          title: Text(
            'Rate ${course!.title}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you rate this course?',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: tempRating.toStringAsFixed(1),
                activeColor: const Color(0xFFFF6949),
                onChanged: (value) {
                  setState(() {
                    tempRating = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _submitRating(tempRating);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6949),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
