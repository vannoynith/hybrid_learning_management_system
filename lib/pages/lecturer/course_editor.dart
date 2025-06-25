import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/services/auth_service.dart';
import 'package:hybridlms/services/firestore_service.dart';
import 'package:hybridlms/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CourseEditor extends StatefulWidget {
  final Course? course;
  final Function(Course)? onSave;

  const CourseEditor({super.key, this.course, this.onSave});

  @override
  _CourseEditorState createState() => _CourseEditorState();
}

class _CourseEditorState extends State<CourseEditor>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _modules = [];
  bool _isPublished = false;
  bool _isLoading = false;
  PlatformFile? _selectedThumbnail;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _snackbarAnimationController;
  late Animation<double> _snackbarFadeAnimation;
  String? _selectedCategory;

  static const List<String> courseCategories = [
    'Network IT',
    'Finance',
    'Accounting',
    'Computer Science',
    'Business Administration',
    'Marketing',
    'Human Resources',
    'Engineering',
    'Medicine',
    'Education',
    'Law',
    'Art and Design',
    'Data Science',
    'Cybersecurity',
    'Project Management',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.course?.title ?? '';
    _descriptionController.text = widget.course?.description ?? '';
    _isPublished = widget.course?.isPublished ?? false;
    _selectedCategory = widget.course?.category ?? courseCategories[0];
    if (widget.course != null) {
      _modules =
          widget.course!.modules
              ?.map(
                (module) => {
                  'id': module['id'] ?? const Uuid().v4(),
                  'name': module['name']?.toString() ?? '',
                  'lessons':
                      (module['lessons'] as List<dynamic>?)
                          ?.map(
                            (lesson) => {
                              'id': lesson['id'] ?? const Uuid().v4(),
                              'name': lesson['name']?.toString() ?? '',
                              'text': lesson['text']?.toString() ?? '',
                              'documents': lesson['documents'] ?? [],
                              'videos': lesson['videos'] ?? [],
                              'images': lesson['images'] ?? [],
                            },
                          )
                          .toList() ??
                      [],
                },
              )
              .toList() ??
          [];
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);
    _snackbarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snackbarFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_snackbarAnimationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    _snackbarAnimationController.dispose();
    super.dispose();
  }

  Future<List<PlatformFile>> _pickFiles({
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    return result?.files ?? [];
  }

  Future<PlatformFile?> _pickThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      final file =
          result?.files.isNotEmpty == true ? result?.files.first : null;
      if (file != null) {
        Uint8List? byteData;
        if (file.bytes == null && file.path != null && !kIsWeb) {
          final fileObj = File(file.path!);
          if (await fileObj.exists()) {
            byteData = await fileObj.readAsBytes();
          } else {
            throw Exception('File not found at path: ${file.path}');
          }
        } else {
          byteData = file.bytes;
        }
        if (kIsWeb && (byteData == null || byteData.isEmpty)) {
          throw Exception('Failed to read bytes from thumbnail: ${file.path}');
        }
        final updatedFile = PlatformFile(
          name: file.name,
          size: file.size,
          path: file.path,
          bytes: byteData,
        );
        print(
          'Selected thumbnail: ${updatedFile.name}, bytes length: ${updatedFile.bytes?.length}, path: ${updatedFile.path}',
        );
        return updatedFile;
      }
      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick thumbnail: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  Future<String?> _uploadFile(
    dynamic file,
    String type,
    String userId,
    String courseId,
    String moduleId,
  ) async {
    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      dynamic uploadData;
      if (kIsWeb) {
        uploadData = file.bytes;
      } else {
        final filePath = file.path!;
        final f = File(filePath);
        if (await f.exists()) {
          uploadData = filePath;
        } else {
          throw Exception('File not found at path: $filePath');
        }
      }
      if (uploadData == null ||
          (uploadData is Uint8List && uploadData.isEmpty)) {
        throw Exception('Invalid file data');
      }
      final url = await firestoreService.uploadToCloudinary(
        uploadData,
        type,
        userId,
        courseId: courseId,
        moduleId: moduleId,
      );
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload $type: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  Future<String?> _uploadThumbnail(String userId) async {
    if (_selectedThumbnail == null) return null;
    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      dynamic uploadData;
      if (kIsWeb) {
        uploadData = _selectedThumbnail!.bytes;
      } else {
        if (_selectedThumbnail!.path != null) {
          final file = File(_selectedThumbnail!.path!);
          if (await file.exists()) {
            uploadData = _selectedThumbnail!.path;
          } else {
            throw Exception(
              'File not found at path: ${_selectedThumbnail!.path}',
            );
          }
        } else {
          throw Exception('No valid path for thumbnail on mobile');
        }
      }
      if (uploadData == null ||
          (uploadData is Uint8List && uploadData.isEmpty) ||
          (uploadData is String && uploadData.isEmpty)) {
        throw Exception('Invalid thumbnail data');
      }
      final url = await firestoreService.uploadToCloudinary(
        uploadData,
        'image',
        userId,
        isThumbnail: true,
        courseId: widget.course?.id ?? const Uuid().v4(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thumbnail uploaded successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      return url;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload thumbnail: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
      return null;
    }
  }

  void _addModule() {
    setState(() {
      _modules.add({
        'id': const Uuid().v4(),
        'name': 'Module ${_modules.length + 1}',
        'lessons': [],
      });
      _animationController.forward(from: 0);
    });
  }

  void _addLesson(int moduleIndex) {
    setState(() {
      final lessons = _modules[moduleIndex]['lessons'] as List<dynamic>? ?? [];
      _modules[moduleIndex]['lessons'].add({
        'id': const Uuid().v4(),
        'name': 'Lesson ${lessons.length + 1}',
        'text': '',
        'documents': [],
        'videos': [],
        'images': [],
      });
      _animationController.forward(from: 0);
    });
  }

  Future<void> _confirmDeleteModule(int moduleIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Confirm Deletion',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to delete this module?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (shouldDelete == true) {
      setState(() => _modules.removeAt(moduleIndex));
    }
  }

  Future<void> _confirmDeleteLesson(int moduleIndex, int lessonIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Confirm Deletion',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to delete this lesson?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (shouldDelete == true) {
      setState(() => _modules[moduleIndex]['lessons'].removeAt(lessonIndex));
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      String? thumbnailUrl = widget.course?.thumbnailUrl;
      if (_selectedThumbnail != null) {
        thumbnailUrl = await _uploadThumbnail(user.uid);
        if (thumbnailUrl == null) throw Exception('Thumbnail upload failed');
      }

      final processedModules = <Map<String, dynamic>>[];
      for (var module in _modules) {
        final processedLessons = <Map<String, dynamic>>[];
        for (var lesson in module['lessons']) {
          final documents = <String>[];
          final videos = <String>[];
          final images = <String>[];

          for (var file in (lesson['documents'] as List<dynamic>?) ?? []) {
            if (file is PlatformFile) {
              final url = await _uploadFile(
                file,
                'doc',
                user.uid,
                widget.course?.id ?? const Uuid().v4(),
                module['id'],
              );
              if (url != null) documents.add(url);
            } else if (file is String) {
              documents.add(file);
            }
          }

          for (var file in (lesson['videos'] as List<dynamic>?) ?? []) {
            // Fixed typo here
            if (file is PlatformFile) {
              final url = await _uploadFile(
                file,
                'video',
                user.uid,
                widget.course?.id ?? const Uuid().v4(),
                module['id'],
              );
              if (url != null) videos.add(url);
            } else if (file is String) {
              videos.add(file);
            }
          }

          for (var file in (lesson['images'] as List<dynamic>?) ?? []) {
            if (file is PlatformFile) {
              final url = await _uploadFile(
                file,
                'image',
                user.uid,
                widget.course?.id ?? const Uuid().v4(),
                module['id'],
              );
              if (url != null) images.add(url);
            } else if (file is String) {
              images.add(file);
            }
          }

          processedLessons.add({
            'id': lesson['id'] ?? const Uuid().v4(),
            'name': lesson['name'] ?? '',
            'text': lesson['text'] ?? '',
            'documents': documents,
            'videos': videos,
            'images': images,
          });
        }

        processedModules.add({
          'id': module['id'] ?? const Uuid().v4(),
          'name': module['name'] ?? '',
          'lessons': processedLessons,
        });
      }

      final courseId = widget.course?.id ?? const Uuid().v4();
      final course = Course(
        id: courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        lecturerId: user.uid,
        isPublished: _isPublished,
        createdAt: widget.course?.createdAt,
        thumbnailUrl: thumbnailUrl,
        modules: processedModules,
        contentUrls:
            processedModules
                .expand((m) => m['lessons'])
                .expand(
                  (l) => [
                    ...l['documents'] as List<dynamic>,
                    ...l['videos'] as List<dynamic>,
                    ...l['images'] as List<dynamic>,
                  ],
                )
                .toList(),
        enrolledCount: widget.course?.enrolledCount ?? 0,
        category: _selectedCategory,
        lecturerDisplayName: '',
      );

      if (widget.onSave != null && widget.course != null) {
        await widget.onSave!(course);
      } else {
        final firestoreService = Provider.of<FirestoreService>(
          context,
          listen: false,
        );
        await firestoreService.saveCourse(user.uid, course);
        if (_isPublished) {
          await firestoreService.publishCourse(course.id, user.uid);
        }
        await firestoreService.saveCourseSubcollections(
          courseId,
          processedModules,
        );
      }

      if (mounted) {
        _snackbarAnimationController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Course ${widget.course == null ? 'created' : 'updated'} successfully',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
            animation: CurvedAnimation(
              parent: _snackbarAnimationController,
              curve: Curves.easeInOut,
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _snackbarAnimationController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to save course: $e',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
            animation: CurvedAnimation(
              parent: _snackbarAnimationController,
              curve: Curves.easeInOut,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    BuildContext? context,
    String? hintText,
  }) {
    final effectiveContext = context ?? this.context;
    final isMobile = MediaQuery.of(effectiveContext).size.width < 600;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6949)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6949), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[700],
          fontSize: isMobile ? 14 : 16,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
      validator: (value) => value!.trim().isEmpty ? '$label is required' : null,
    );
  }

  Widget _buildFilePicker({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required List<dynamic> files,
    required String fileType,
    List<String>? allowedExtensions,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: const Color(0xFFFF6949)),
                const SizedBox(width: 8),
                Text(
                  'Upload $fileType',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                files.asMap().entries.map((entry) {
                  final file = entry.value;
                  final fileName =
                      file is PlatformFile
                          ? file.name
                          : file.toString().split('/').last;
                  return Chip(
                    label: Text(
                      fileName,
                      style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => files.removeAt(entry.key));
                    },
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  );
                }).toList(),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLessonContent(int moduleIndex, int lessonIndex) {
    final lesson = _modules[moduleIndex]['lessons'][lessonIndex];
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: lesson['text'],
            decoration: InputDecoration(
              labelText: 'Lesson Content',
              hintText: 'Enter lesson content (e.g., lecture notes)',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              prefixIcon: const Icon(
                Icons.text_fields,
                color: Color(0xFFFF6949),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6949),
                  width: 2,
                ),
              ),
              labelStyle: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            maxLines: 4,
            onChanged: (value) => setState(() => lesson['text'] = value),
          ),
          const SizedBox(height: 16),
          _buildFilePicker(
            label: 'Upload Documents',
            icon: Icons.upload_file,
            onTap: () async {
              final files = await _pickFiles(
                allowedExtensions: ['pdf', 'doc', 'docx'],
              );
              if (files.isNotEmpty) {
                setState(() => lesson['documents'] = files);
              }
            },
            files: lesson['documents'] ?? [],
            fileType: 'Documents',
            allowedExtensions: ['pdf', 'doc', 'docx'],
          ),
          _buildFilePicker(
            label: 'Upload Videos',
            icon: Icons.video_library,
            onTap: () async {
              final files = await _pickFiles(allowedExtensions: ['mp4', 'mov']);
              if (files.isNotEmpty) {
                setState(() => lesson['videos'] = files);
              }
            },
            files: lesson['videos'] ?? [],
            fileType: 'Videos',
            allowedExtensions: ['mp4', 'mov'],
          ),
          _buildFilePicker(
            label: 'Upload Images',
            icon: Icons.image,
            onTap: () async {
              final files = await _pickFiles(
                allowedExtensions: ['jpg', 'jpeg', 'png'],
              );
              if (files.isNotEmpty) {
                setState(() => lesson['images'] = files);
              }
            },
            files: lesson['images'] ?? [],
            fileType: 'Images',
            allowedExtensions: ['jpg', 'jpeg', 'png'],
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: isMobile ? 12 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFFFF6949),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildModuleSection(int moduleIndex) {
    final module = _modules[moduleIndex];
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isExpanded = _modules[moduleIndex]['isExpanded'] ?? false;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: ExpansionTile(
          leading: const Icon(Icons.library_books, color: Color(0xFFFF6949)),
          title: TextFormField(
            initialValue: module['name'],
            decoration: InputDecoration(
              hintText: 'Enter module name (e.g., Introduction)',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            onChanged: (value) => setState(() => module['name'] = value),
            validator:
                (value) =>
                    value!.trim().isEmpty ? 'Module name is required' : null,
          ),
          trailing: Tooltip(
            message: 'Click to expand/collapse module',
            child: RotationTransition(
              turns: Tween<double>(begin: 0, end: 0.5).animate(
                CurvedAnimation(
                  parent: AnimationController(
                    vsync: this,
                    duration: const Duration(milliseconds: 200),
                  )..forward(from: isExpanded ? 0.5 : 0),
                  curve: Curves.easeInOut,
                ),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),
          tilePadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 8 : 12,
          ),
          childrenPadding: const EdgeInsets.only(
            bottom: 16,
            left: 16,
            right: 16,
          ),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _modules[moduleIndex]['isExpanded'] = expanded;
            });
          },
          children: [
            ...module['lessons'].asMap().entries.map((lessonEntry) {
              final lessonIndex = lessonEntry.key;
              final lesson = lessonEntry.value;
              final isLessonExpanded = lesson['isExpanded'] ?? false;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  leading: const Icon(Icons.bookmark, color: Color(0xFFFF6949)),
                  title: TextFormField(
                    initialValue: lesson['name'],
                    decoration: InputDecoration(
                      hintText: 'Enter lesson name (e.g., Course Overview)',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    onChanged:
                        (value) => setState(() => lesson['name'] = value),
                    validator:
                        (value) =>
                            value!.trim().isEmpty
                                ? 'Lesson name is required'
                                : null,
                  ),
                  trailing: Tooltip(
                    message: 'Click to expand/collapse lesson',
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0, end: 0.5).animate(
                        CurvedAnimation(
                          parent: AnimationController(
                            vsync: this,
                            duration: const Duration(milliseconds: 200),
                          )..forward(from: isLessonExpanded ? 0.5 : 0),
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isMobile ? 6 : 8,
                  ),
                  childrenPadding: const EdgeInsets.only(
                    bottom: 12,
                    left: 12,
                    right: 12,
                  ),
                  backgroundColor: Colors.grey[50],
                  collapsedBackgroundColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      lesson['isExpanded'] = expanded;
                    });
                  },
                  children: [_buildLessonContent(moduleIndex, lessonIndex)],
                ),
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildModernButton(
                label: 'Add Lesson',
                icon: Icons.add,
                onPressed: () => _addLesson(moduleIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body:
          _isLoading
              ? const LoadingIndicator()
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    toolbarHeight: 60,
                    titleSpacing: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        widget.course == null ? 'Create Course' : 'Edit Course',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
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
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: 16,
                      ),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.course == null
                                      ? 'Create New Course'
                                      : 'Edit Course',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: isMobile ? 24 : 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fill in the details to ${widget.course == null ? 'create' : 'update'} your course',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  controller: _titleController,
                                  label: 'Course Title',
                                  icon: Icons.book,
                                  hintText:
                                      'Enter course title (e.g., Learn Flutter)',
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    hintText: 'Select a course category',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.category,
                                      color: Color(0xFFFF6949),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
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
                                        color: Color(0xFFFF6949),
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.grey[700],
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                                  items:
                                      courseCategories.map((String category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(
                                            category,
                                            style: GoogleFonts.poppins(
                                              fontSize: isMobile ? 14 : 16,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(
                                      () => _selectedCategory = newValue,
                                    );
                                  },
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Please select a category'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _descriptionController,
                                  label: 'Description',
                                  icon: Icons.description,
                                  maxLines: 4,
                                  hintText: 'Provide a brief course overview',
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Thumbnail',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildFilePicker(
                                  label: 'Upload Thumbnail',
                                  icon: Icons.image,
                                  onTap: () async {
                                    final file = await _pickThumbnail();
                                    if (file != null) {
                                      setState(() => _selectedThumbnail = file);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Thumbnail selected: ${file.name}',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  files:
                                      _selectedThumbnail != null
                                          ? [_selectedThumbnail!]
                                          : <PlatformFile>[],
                                  fileType: 'Thumbnail',
                                  allowedExtensions: ['jpg', 'jpeg', 'png'],
                                ),
                                if (_selectedThumbnail != null ||
                                    (widget.course?.thumbnailUrl != null &&
                                        widget.course != null))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            _selectedThumbnail != null
                                                ? _selectedThumbnail!.bytes !=
                                                        null
                                                    ? 'data:image/png;base64,${base64Encode(_selectedThumbnail!.bytes!)}'
                                                    : widget
                                                            .course
                                                            ?.thumbnailUrl ??
                                                        ''
                                                : widget.course!.thumbnailUrl!,
                                            width: 150,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                width: 150,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: Text(
                                                    'Image failed to load',
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (_selectedThumbnail != null)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed:
                                                () => setState(
                                                  () =>
                                                      _selectedThumbnail = null,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                Text(
                                  'Modules',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._modules.asMap().entries.map(
                                  (entry) => _buildModuleSection(entry.key),
                                ),
                                const SizedBox(height: 16),
                                _buildModernButton(
                                  label: 'Add Module',
                                  icon: Icons.add,
                                  onPressed: _addModule,
                                ),
                                const SizedBox(height: 24),
                                _buildModernButton(
                                  label: 'Save Course',
                                  icon: Icons.save,
                                  onPressed: _saveCourse,
                                  isLoading: _isLoading,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
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
