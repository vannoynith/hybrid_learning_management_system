import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_button.dart';
import '../../models/interaction.dart';

class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({super.key});

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();
  String? _selectedSex;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureAdminPassword = true;
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _emailController.text = '@adminhlms.com';
    _emailController.selection = TextSelection.fromPosition(
      TextPosition(offset: 0),
    );
  }

  Future<bool> _verifyAdminPassword() async {
    try {
      final isValid = await _authService.reAuthenticateAdmin(
        _adminPasswordController.text,
      );
      if (!isValid) {
        _showSnackBar('Incorrect admin password');
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('Authentication failed: ${e.toString()}');
      return false;
    }
  }

  Future<void> _createAdmin() async {
    final errors = <String>[];
    if (_nameController.text.trim().isEmpty) {
      errors.add('Please enter a name');
    } else if (_nameController.text.trim().length < 2) {
      errors.add('Name must be at least 2 characters');
    }
    if (_emailController.text.trim().isEmpty) {
      errors.add('Please enter an email');
    } else if (!_emailController.text.trim().endsWith('@adminhlms.com')) {
      errors.add('Email must end with @adminhlms.com');
    } else if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@adminhlms\.com$',
    ).hasMatch(_emailController.text.trim())) {
      errors.add('Invalid email format');
    }
    if (_phoneController.text.trim().isEmpty) {
      errors.add('Please enter a phone number');
    } else if (!RegExp(
      r'^\+?[\d\s-]{10,}$',
    ).hasMatch(_phoneController.text.trim())) {
      errors.add('Invalid phone number format');
    }
    if (_selectedSex == null) {
      errors.add('Please select a sex');
    }
    if (_passwordController.text.trim().isEmpty) {
      errors.add('Please enter a password');
    } else if (_passwordController.text.trim().length < 8) {
      errors.add('Password must be at least 8 characters');
    } else if (!RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    ).hasMatch(_passwordController.text.trim())) {
      errors.add('Must include uppercase, lowercase, number, and symbol');
    }
    if (_adminPasswordController.text.trim().isEmpty) {
      errors.add('Please enter your admin password');
    }

    if (errors.isNotEmpty) {
      _showSnackBar(errors.first);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Admin Creation'),
            content: const Text(
              'Are you sure you want to create this admin account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('No user logged in');

      final isVerified = await _verifyAdminPassword();
      if (!isVerified) {
        setState(() => _isLoading = false);
        return;
      }

      final email = _emailController.text.trim();
      final newUser = await _authService.createUserWithoutSignIn(
        email,
        _passwordController.text.trim(),
        'admin',
        username: _nameController.text.trim(),
      );

      if (newUser == null) throw Exception('Failed to create user');

      await _firestoreService.saveUser(
        newUser.uid,
        email,
        'admin',
        username: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _selectedSex,
      );

      final interaction = Interaction(
        userId: currentUser.uid,
        action: 'create_admin',
        targetId: newUser.uid,
        details: 'Created admin: $email',
        timestamp: Timestamp.now(),
        adminName: currentUser.email?.split('@')[0] ?? 'Unknown Admin',
      );
      await _firestoreService.logInteraction(interaction);

      _showSnackBar('Admin created successfully: $email');
      _clearForm();
    } catch (e) {
      String errorMessage = 'Failed to create admin';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already in use';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error, please try again';
      } else {
        errorMessage = 'Failed to create admin: ${e.toString()}';
      }
      _showSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.text = '@adminhlms.com';
    _emailController.selection = TextSelection.fromPosition(
      TextPosition(offset: 0),
    );
    _passwordController.clear();
    _phoneController.clear();
    _adminPasswordController.clear();
    setState(() => _selectedSex = null);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              message.contains('success') ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor:
            message.contains('success')
                ? Colors.green
                : const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.06,
                vertical: constraints.maxHeight * 0.03,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Admin',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.01),
                    Text(
                      'Fill in the details to create an admin account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.04),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    DropdownButtonFormField<String>(
                      value: _selectedSex,
                      decoration: InputDecoration(
                        labelText: 'Sex',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF4B5563),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                          ),
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
                      onChanged:
                          (value) => setState(() => _selectedSex = value),
                      hint: const Text('Select Sex'),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF4B5563),
                        ),
                        onPressed:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    _buildTextField(
                      controller: _adminPasswordController,
                      label: 'Your Admin Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureAdminPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureAdminPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF4B5563),
                        ),
                        onPressed:
                            () => setState(
                              () =>
                                  _obscureAdminPassword =
                                      !_obscureAdminPassword,
                            ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.04),
                    _isLoading
                        ? const LoadingIndicator()
                        : CustomButton(
                          text: 'Create Admin',
                          onPressed: _createAdmin,
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4B5563)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF4B5563)),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }
}
