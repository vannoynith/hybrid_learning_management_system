import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_button.dart';
import 'change_password_for_lecturer_page.dart';

class LecturerSettingsPage extends StatefulWidget {
  const LecturerSettingsPage({super.key});

  @override
  State<LecturerSettingsPage> createState() => _LecturerSettingsPageState();
}

class _LecturerSettingsPageState extends State<LecturerSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _profileImageUrl;
  String? _selectedSex;
  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _userData;
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('No user logged in');
      _userData = await _firestoreService.getUser(currentUser.uid);
      if (_userData != null) {
        _nameController.text = _userData!['displayName'] ?? '';
        _phoneController.text = _userData!['phoneNumber'] ?? '';
        _majorController.text = _userData!['address'] ?? '';
        _degreeController.text = _userData!['position'] ?? '';
        _dobController.text = _userData!['dateOfBirth'] ?? '';
        _profileImageUrl = _userData!['profileImageUrl'];
        final userSex = _userData!['userSex'] as String?;
        _selectedSex = _sexOptions.contains(userSex) ? userSex : null;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfileImage() async {
    setState(() => _isUploading = true);
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('No user logged in');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        if (kIsWeb) {
          if (result.files.single.bytes != null) {
            await _firestoreService.uploadProfilePicture(
              result.files.single.bytes!,
              currentUser.uid,
              currentUser.uid,
            );
          }
        } else {
          if (result.files.single.path != null) {
            await _firestoreService.uploadProfilePicture(
              result.files.single.path!,
              currentUser.uid,
              currentUser.uid,
            );
          }
        }
        _userData = await _firestoreService.getUser(currentUser.uid);
        setState(() => _profileImageUrl = _userData!['profileImageUrl']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('No user logged in');
      await _firestoreService.saveUser(
        currentUser.uid,
        _userData!['email'] ?? currentUser.email!,
        'lecturer',
        username: _nameController.text.trim(),
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _majorController.text.trim(),
        position: _degreeController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        userSex: _selectedSex,
        profileImageUrl: _profileImageUrl,
        passwordUpdatedAt: null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: const Color.fromARGB(255, 255, 0, 0),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _majorController.dispose();
    _degreeController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? const Center(child: LoadingIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    toolbarHeight: 60,
                    titleSpacing: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Profile Settings',
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Profile',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6949),
                                    fontSize: isMobile ? 24 : 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage your personal information',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundImage:
                                            _profileImageUrl != null
                                                ? NetworkImage(
                                                  _profileImageUrl!,
                                                )
                                                : null,
                                        child:
                                            _profileImageUrl == null
                                                ? const Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: Colors.white,
                                                )
                                                : null,
                                        backgroundColor: const Color(
                                          0xFFFF6949,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: ElevatedButton(
                                          onPressed:
                                              _isUploading
                                                  ? null
                                                  : _uploadProfileImage,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.all(8),
                                            shape: const CircleBorder(),
                                            backgroundColor: const Color(
                                              0xFFFF6949,
                                            ),
                                            elevation: 4,
                                          ),
                                          child:
                                              _isUploading
                                                  ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : const Icon(
                                                    Icons.camera_alt,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person,
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Please enter a name'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator:
                                      (value) =>
                                          value != null &&
                                                  value.isNotEmpty &&
                                                  !RegExp(
                                                    r'^\+?[\d\s-]{10,}$',
                                                  ).hasMatch(value)
                                              ? 'Invalid phone number format'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _dobController,
                                  label: 'Date of Birth (YYYY-MM-DD)',
                                  icon: Icons.calendar_today,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Please select a date of birth'
                                              : !RegExp(
                                                r'^\d{4}-\d{2}-\d{2}$',
                                              ).hasMatch(value)
                                              ? 'Invalid date format (use YYYY-MM-DD)'
                                              : DateFormat('yyyy-MM-dd')
                                                  .parseStrict(value)
                                                  .isAfter(DateTime.now())
                                              ? 'Date cannot be in the future'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _majorController,
                                  label: 'Major/Department',
                                  icon: Icons.school,
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Please enter a major/department'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _degreeController,
                                  label: 'Degree',
                                  icon: Icons.book,
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Please enter a degree'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedSex,
                                  decoration: InputDecoration(
                                    labelText: 'Sex',
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: const Color(0xFFFF6949),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    errorMaxLines: 2,
                                  ),
                                  hint: Text(
                                    'Select sex',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  items:
                                      _sexOptions
                                          .map(
                                            (sex) => DropdownMenuItem(
                                              value: sex,
                                              child: Text(
                                                sex,
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (value) =>
                                          setState(() => _selectedSex = value),
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Please select a sex'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const ChangePasswordForLecturerPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Change Password',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFFF6949),
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 14 : 16,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Update Profile',
                                  onPressed: _updateProfile,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 12 : 16,
                                    horizontal: isMobile ? 24 : 32,
                                  ),
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  elevation: 4,
                                  borderRadius: 16,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6949)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6949), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 16),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}
