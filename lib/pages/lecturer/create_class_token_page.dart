import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/services/auth_service.dart';
import 'package:hybridlms/services/firestore_service.dart';
import 'package:hybridlms/widgets/loading_indicator.dart';
import 'package:uuid/uuid.dart';

class CreateClassTokenPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CreateClassTokenPage({super.key, this.arguments});

  @override
  _CreateClassTokenPageState createState() => _CreateClassTokenPageState();
}

class _CreateClassTokenPageState extends State<CreateClassTokenPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _courseId;
  String? _errorMessage;
  String? _generatedToken;
  DateTime? _customDeadline;
  String? _selectedDeadlineOption = '3 Months';
  final List<String> _deadlineOptions = [
    '3 Months',
    '6 Months',
    '1 Year',
    'Permanent',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _courseId = widget.arguments?['courseId'] as String?;
    if (_courseId == null || _courseId!.isEmpty) {
      setState(() {
        _errorMessage = 'No course ID provided.';
      });
    }
  }

  Future<void> _createClass() async {
    if (_courseId == null || _courseId!.isEmpty) {
      setState(() {
        _errorMessage = 'No course ID provided.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No user logged in');

      // Calculate deadline based on selected option
      DateTime? deadline;
      if (_selectedDeadlineOption == '3 Months') {
        deadline = DateTime.now().add(const Duration(days: 90));
      } else if (_selectedDeadlineOption == '6 Months') {
        deadline = DateTime.now().add(const Duration(days: 180));
      } else if (_selectedDeadlineOption == '1 Year') {
        deadline = DateTime.now().add(const Duration(days: 365));
      } else if (_selectedDeadlineOption == 'Custom' &&
          _customDeadline != null) {
        deadline = _customDeadline;
      } else if (_selectedDeadlineOption == 'Permanent') {
        deadline = null; // No deadline
      } else {
        throw Exception('Invalid deadline option.');
      }

      // Generate unique token
      final token = const Uuid().v4().substring(0, 8).toUpperCase();

      // Save class to Firestore
      await _firestoreService.createClass(
        courseId: _courseId!,
        lecturerId: user.uid,
        token: token,
        deadline: deadline,
      );

      setState(() {
        _generatedToken = token;
        _errorMessage = null;
      });

      _showSnackBar('Class created successfully! Token: $token', Colors.green);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create class: $e';
      });
      _showSnackBar('Failed to create class: $e', const Color(0xFFEF4444));
    } finally {
      setState(() => _isLoading = false);
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

  Future<void> _selectCustomDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      setState(() {
        _customDeadline = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
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
                        'Create Class Token',
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
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create a Class for Course',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 20 : 24,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              if (_generatedToken != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class Created Successfully!',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 16 : 18,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Token: $_generatedToken',
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Deadline: ${_selectedDeadlineOption == 'Custom' ? _customDeadline?.toString().split(' ')[0] : _selectedDeadlineOption}',
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 14 : 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
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
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          48,
                                        ),
                                      ),
                                      child: Text(
                                        'Back to Course Management',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Deadline',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 16 : 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedDeadlineOption,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFF6949),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      items:
                                          _deadlineOptions
                                              .map(
                                                (option) => DropdownMenuItem(
                                                  value: option,
                                                  child: Text(
                                                    option,
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDeadlineOption = value;
                                          if (value != 'Custom') {
                                            _customDeadline = null;
                                          }
                                        });
                                      },
                                    ),
                                    if (_selectedDeadlineOption ==
                                        'Custom') ...[
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _selectCustomDate,
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
                                        child: Text(
                                          _customDeadline == null
                                              ? 'Select Custom Date'
                                              : 'Selected: ${_customDeadline!.toString().split(' ')[0]}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: isMobile ? 14 : 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _createClass,
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
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          48,
                                        ),
                                      ),
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : Text(
                                                'Create Class',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                    ),
                                  ],
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
