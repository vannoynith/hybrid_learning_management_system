import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_button.dart';

class LecturerSettingsPage extends StatefulWidget {
  const LecturerSettingsPage({super.key});

  @override
  State<LecturerSettingsPage> createState() => _LecturerSettingsPageState();
}

class _LecturerSettingsPageState extends State<LecturerSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
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
        _profileImageUrl = _userData!['profileImageUrl'];
        _selectedSex = _userData!['dateOfBirth'];
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        String url = await _firestoreService.uploadToCloudinary(
          result.files.single.path!,
          'image',
        );
        setState(() => _profileImageUrl = url);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _updateProfile() async {
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
        dateOfBirth: _selectedSex,
      );
      // Update profile image separately if changed
      if (_profileImageUrl != _userData!['profileImageUrl']) {
        await _firestoreService.db
            .collection('users')
            .doc(currentUser.uid)
            .update({'profileImageUrl': _profileImageUrl});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          _isLoading
              ? const LoadingIndicator()
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Profile',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage:
                                        _profileImageUrl != null
                                            ? NetworkImage(_profileImageUrl!)
                                            : null,
                                    child:
                                        _profileImageUrl == null
                                            ? const Icon(Icons.person, size: 50)
                                            : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon:
                                          _isUploading
                                              ? const CircularProgressIndicator()
                                              : const Icon(Icons.camera_alt),
                                      onPressed:
                                          _isUploading
                                              ? null
                                              : _uploadProfileImage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    !RegExp(
                                      r'^\+?[\d\s-]{10,}$',
                                    ).hasMatch(value)) {
                                  return 'Invalid phone number format';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _majorController,
                              label: 'Major/Department',
                              icon: Icons.school,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a major/department';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _degreeController,
                              label: 'Degree',
                              icon: Icons.book,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a degree';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _selectedSex,
                              decoration: InputDecoration(
                                labelText: 'Sex',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Theme.of(context).primaryColor,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items:
                                  _sexOptions
                                      .map(
                                        (sex) => DropdownMenuItem(
                                          value: sex,
                                          child: Text(sex),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() => _selectedSex = value);
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Please select a sex'
                                          : null,
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: 'Update Profile',
                              onPressed: _updateProfile,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
