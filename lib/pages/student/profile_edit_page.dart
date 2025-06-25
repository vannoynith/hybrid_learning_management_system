import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hybridlms/pages/lecturer/change_password_for_lecturer_page.dart';
import 'package:hybridlms/pages/student/change_password_page.dart';
import 'package:hybridlms/widgets/custom_bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../routes.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_button.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _profileImageUrl;
  String? _selectedSex;
  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _userData;
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  int _selectedIndex = 1;

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
        _addressController.text = _userData!['address'] ?? '';
        _dobController.text = _userData!['dateOfBirth'] ?? '';
        _profileImageUrl = _userData!['profileImageUrl'];
        final userSex = _userData!['userSex'] as String?;
        _selectedSex = _sexOptions.contains(userSex) ? userSex : null;
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load profile: $e', const Color(0xFFEF4444));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    setState(() => _isUploading = true);
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('No user logged in');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
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
        if (mounted) {
          setState(() => _profileImageUrl = _userData!['profileImageUrl']);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to upload image: $e', const Color(0xFFEF4444));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
        currentUser.email!,
        _userData!['role'] ?? 'student',
        username: _nameController.text.trim(),
        displayName: _nameController.text.trim(),
        phoneNumber:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
        address:
            _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
        dateOfBirth:
            _dobController.text.trim().isEmpty
                ? null
                : _dobController.text.trim(),
        userSex: _selectedSex,
        profileImageUrl: _profileImageUrl,
        passwordUpdatedAt: null,
      );
      if (mounted) {
        _showSnackBar('Profile updated successfully', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update profile: $e', const Color(0xFFEF4444));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.dashboard);
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.chat);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Routes.notification);
        break;
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, Routes.login);
      });
      return const Center(child: CircularProgressIndicator());
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: Drawer(
        backgroundColor: const Color(0xFFF7F7F7),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6949), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child:
                        _userData?['profileImageUrl'] != null &&
                                _userData!['profileImageUrl'].isNotEmpty
                            ? ClipOval(
                              child: Image.network(
                                _userData!['profileImageUrl'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color(0xFFFF6949),
                                    ),
                              ),
                            )
                            : const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFFFF6949),
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData?['displayName'] ?? 'User Name',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _userData?['email'] ?? 'user@example.com',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'Dashboard',
              route: Routes.dashboard,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.book,
              title: 'Courses',
              route: Routes.courseList,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Profile',
              route: Routes.profileEdit,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.timeline,
              title: 'Timeline',
              route: Routes.timeline,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.analytics,
              title: 'Analytics',
              route: Routes.analytics,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.assignment,
              title: 'Assignments',
              route: Routes.assignment,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.chat,
              title: 'Chat',
              route: Routes.chat,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.play_circle,
              title: 'Lectures',
              route: Routes.lecture,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'Lecturers',
              route: Routes.lecturers,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              route: Routes.notification,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.quiz,
              title: 'Quizzes',
              route: Routes.quiz,
            ),
            const Divider(color: Color(0xFFE5E7EB)),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onTap: () async {
                await _authService.signOut();
                Navigator.pushReplacementNamed(context, Routes.login);
              },
            ),
          ],
        ),
      ),
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
                    leading: Builder(
                      builder:
                          (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Menu',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            style: IconButton.styleFrom(),
                          ),
                    ),
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
                                          value == null || value.isEmpty
                                              ? 'Name is required'
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
                                  label: 'Date of Birth',
                                  icon: Icons.calendar_today,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                  validator:
                                      (value) =>
                                          value != null && value.isNotEmpty
                                              ? (!RegExp(
                                                    r'^\d{4}-\d{2}-\d{2}$',
                                                  ).hasMatch(value)
                                                  ? 'Invalid date format (YYYY-MM-DD)'
                                                  : DateFormat('yyyy-MM-dd')
                                                      .parseStrict(value)
                                                      .isAfter(DateTime.now())
                                                  ? 'Date cannot be in the future'
                                                  : null)
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _addressController,
                                  label: 'Address',
                                  icon: Icons.location_on,
                                  validator: null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedSex,
                                  decoration: InputDecoration(
                                    labelText: 'Sex',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFFFF6949),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFF6949),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
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
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                _userData?['role'] == 'lecturer'
                                                    ? const ChangePasswordForLecturerPage()
                                                    : const ChangePasswordForStudentPage(),
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
                                  text: 'Save Changes',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavItemTapped,
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
        labelStyle: GoogleFonts.poppins(color: Colors.grey[800], fontSize: 16),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF6949)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
