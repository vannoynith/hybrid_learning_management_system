import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hybridlms/widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';

class ChangePasswordForAdminPage extends StatefulWidget {
  const ChangePasswordForAdminPage({super.key});

  @override
  State<ChangePasswordForAdminPage> createState() =>
      _ChangePasswordForAdminPageState();
}

class _ChangePasswordForAdminPageState
    extends State<ChangePasswordForAdminPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('No user logged in');

      // Re-authenticate with old password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _oldPasswordController.text.trim(),
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Validate new password matches confirmation
      if (_newPasswordController.text.trim() !=
          _confirmPasswordController.text.trim()) {
        throw Exception('New password and confirmation do not match');
      }

      // Update password
      await currentUser.updatePassword(_newPasswordController.text.trim());

      // Update only the passwordUpdatedAt timestamp in Firestore
      await _firestoreService.saveUser(
        currentUser.uid,
        currentUser.email!,
        'admin',
        passwordUpdatedAt: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Password updated successfully!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50), // Green for success
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );
        Navigator.pop(context); // Return to previous page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.toString().contains('match')
                        ? 'New password and confirmation do not match. Please try again.'
                        : 'Failed to update password. Please check your current password and try again.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF6949), // Orange from app theme
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
                        'Change Password',
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
                                  'Update Password',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6949),
                                    fontSize: isMobile ? 24 : 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter your current and new password',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  controller: _oldPasswordController,
                                  label: 'Current Password',
                                  icon: Icons.lock,
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Please enter your current password'
                                              : null,
                                  obscureText: true,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _newPasswordController,
                                  label: 'New Password',
                                  icon: Icons.lock,
                                  validator:
                                      (value) =>
                                          value != null &&
                                                  value.isNotEmpty &&
                                                  value.length < 6
                                              ? 'Password must be at least 6 characters'
                                              : null,
                                  obscureText: true,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm New Password',
                                  icon: Icons.lock,
                                  validator: (value) {
                                    if (value != _newPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Change Password',
                                  onPressed: _changePassword,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 12 : 16,
                                    horizontal: isMobile ? 24 : 32,
                                  ),
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
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
    String? Function(String?)? validator,
    bool obscureText = false,
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
      validator: validator,
      obscureText: obscureText,
    );
  }
}
