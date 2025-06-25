import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/routes.dart';
import 'package:hybridlms/services/auth_service.dart';
import 'package:hybridlms/services/firestore_service.dart';
import 'package:hybridlms/widgets/loading_indicator.dart';
import 'dart:ui';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  _CourseManagementPageState createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  static const _primaryColor = Color(0xFFFF6949);
  static const _backgroundColor = Color(0xFFF5F7FA);
  static const _cardColor = Colors.white;
  static const _errorColor = Color(0xFFEF4444);
  static const _successColor = Colors.green;
  static const _animationDuration = Duration(milliseconds: 400);
  static const _animationCurve = Curves.easeInOut;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Course> _courses = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No user logged in');
      _courses = await _firestoreService.getLecturerCourses(user.uid);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load courses: $e', _errorColor);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _publishCourse(String courseId) async {
    setState(() => _isProcessing = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No user logged in');
      await _firestoreService.publishCourse(courseId, user.uid);
      await _loadCourses();
      if (mounted) {
        _showSnackBar('Course published successfully', _successColor);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to publish course: $e', _errorColor);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _disableCourse(String courseId) async {
    setState(() => _isProcessing = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No user logged in');
      await _firestoreService.disableCourse(courseId, user.uid);
      await _loadCourses();
      if (mounted) {
        _showSnackBar('Course disabled successfully', _successColor);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to disable course: $e', _errorColor);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Confirm Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to delete this course?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: _errorColor),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No user logged in');
      await _firestoreService.deleteCourse(courseId, user.uid);
      await _loadCourses();
      if (mounted) {
        _showSnackBar('Course deleted successfully', _successColor);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to delete course: $e', _errorColor);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == _errorColor
                  ? Icons.error_outline
                  : Icons.check_circle,
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
      ),
    );
  }

  List<Course> _filteredCourses() {
    if (_searchQuery.isEmpty) return _courses;
    return _courses
        .where((course) => course.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Widget _buildCourseCard(Course course, bool isMobile) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  course.thumbnailUrl!,
                  height: isMobile ? 120 : 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: isMobile ? 120 : 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                ),
              ),
            if (course.thumbnailUrl != null) const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedScale(
                  scale: 1.0,
                  duration: _animationDuration,
                  child: IconButton(
                    tooltip: 'Course Actions',
                    icon: const Icon(
                      Icons.more_vert,
                      color: _primaryColor,
                      size: 28,
                    ),
                    onPressed: () => _showCourseActions(context, course),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${course.isPublished ? 'Published' : 'Draft'}',
              style: GoogleFonts.poppins(
                color:
                    course.isPublished ? Colors.green[700] : Colors.grey[600],
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            Text(
              'Enrollments: ${course.enrolledCount}',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            Text(
              'Category: ${course.category ?? 'N/A'}',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseActions(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5, // Reduced from 0.6
            minChildSize: 0.3, // Reduced from 0.4
            maxChildSize: 0.7, // Reduced from 0.8
            builder:
                (context, scrollController) => _CourseActionsBottomSheet(
                  course: course,
                  onPublish: () => _publishCourse(course.id),
                  onDisable: () => _disableCourse(course.id),
                  onEdit:
                      () => Navigator.pushNamed(
                        context,
                        Routes.updateCourse,
                        arguments: course.id,
                      ),
                  onDelete: () => _deleteCourse(course.id),
                  onView:
                      () => Navigator.pushNamed(
                        context,
                        Routes.contentViewPage,
                        arguments: course,
                      ),
                  onCreateClass:
                      () => Navigator.pushNamed(
                        context,
                        Routes.createClassToken,
                        arguments: {'courseId': course.id},
                      ),
                  scrollController: scrollController,
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _filteredCourses();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _backgroundColor,

      body:
          _isLoading || _isProcessing
              ? const Center(child: LoadingIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: isMobile ? 200 : 250,
                    floating: false,
                    pinned: true,
                    toolbarHeight: 60,
                    titleSpacing: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Manage Courses',
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
                            colors: [_primaryColor, Color(0xFFFF8A65)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    backgroundColor: _primaryColor,
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh Courses',
                        onPressed: _loadCourses,
                      ),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Courses: ${filteredCourses.length}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: isMobile ? 16 : 20,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search courses by title...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: _primaryColor,
                                  ),
                                  suffixIcon:
                                      _searchQuery.isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              color: Colors.grey,
                                            ),
                                            onPressed:
                                                () => _searchController.clear(),
                                          )
                                          : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: _cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (filteredCourses.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'No courses found.',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              else
                                ...filteredCourses.map(
                                  (course) =>
                                      _buildCourseCard(course, isMobile),
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
}

class _CourseActionsBottomSheet extends StatefulWidget {
  final Course course;
  final VoidCallback onPublish;
  final VoidCallback onDisable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final VoidCallback onCreateClass;
  final ScrollController scrollController;

  const _CourseActionsBottomSheet({
    required this.course,
    required this.onPublish,
    required this.onDisable,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    required this.onCreateClass,
    required this.scrollController,
  });

  @override
  _CourseActionsBottomSheetState createState() =>
      _CourseActionsBottomSheetState();
}

class _CourseActionsBottomSheetState extends State<_CourseActionsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350), // Reduced from 400
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));
    _fadeAnimation = Tween<double>(
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
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SafeArea(
                    bottom: false, // Prevent bottom padding from system UI
                    child: Container(
                      decoration: BoxDecoration(
                        color: _CourseManagementPageState._cardColor
                            .withOpacity(0.7),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ), // Reduced from 8
                            child: Container(
                              width: 36, // Slightly smaller
                              height: 4, // Slightly thinner
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [],
                            ),
                          ),
                          // Actions
                          Flexible(
                            child: SingleChildScrollView(
                              controller: widget.scrollController,
                              physics: const BouncingScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ), // Reduced bottom padding from 16
                                child: Column(
                                  children: [
                                    _ActionButton(
                                      icon:
                                          widget.course.isPublished
                                              ? Icons.visibility_off
                                              : Icons.publish,
                                      label:
                                          widget.course.isPublished
                                              ? 'Disable Course'
                                              : 'Publish Course',
                                      color:
                                          _CourseManagementPageState
                                              ._primaryColor,
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.course.isPublished
                                            ? widget.onDisable()
                                            : widget.onPublish();
                                      },
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ), // Reduced from 12
                                    _ActionButton(
                                      icon: Icons.edit,
                                      label: 'Edit Course',
                                      color:
                                          _CourseManagementPageState
                                              ._primaryColor,
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onEdit();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _ActionButton(
                                      icon: Icons.delete,
                                      label: 'Delete Course',
                                      color:
                                          _CourseManagementPageState
                                              ._errorColor,
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onDelete();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _ActionButton(
                                      icon: Icons.visibility,
                                      label: 'View Content',
                                      color:
                                          _CourseManagementPageState
                                              ._primaryColor,
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onView();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _ActionButton(
                                      icon: Icons.class_,
                                      label: 'Create Class',
                                      color:
                                          _CourseManagementPageState
                                              ._primaryColor,
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onCreateClass();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _ActionButton(
                                      icon: Icons.close,
                                      label: 'Cancel',
                                      color: Colors.grey,
                                      isSecondary: true,
                                      onTap: () => Navigator.pop(context),
                                    ),
                                  ],
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
            ),
          ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder:
              (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.isSecondary
                            ? Colors.grey[200]
                            : _CourseManagementPageState._cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: widget.color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.color,
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
}
