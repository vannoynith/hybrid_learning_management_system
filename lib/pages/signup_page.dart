import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../routes.dart';
import '../widgets/loading_indicator.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true;

  Future<void> _signUp() async {
    if (isLoading) return; // Prevent multiple simultaneous sign-ups
    setState(() => isLoading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Input validation
      if (username.isEmpty) {
        _showSnackBar('Please enter a username.', isError: true);
        return;
      }
      if (email.isEmpty) {
        _showSnackBar('Please enter an email address.', isError: true);
        return;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _showSnackBar('Please enter a valid email address.', isError: true);
        return;
      }
      if (password.isEmpty) {
        _showSnackBar('Please enter a password.', isError: true);
        return;
      }
      if (password.length < 6) {
        _showSnackBar(
          'Password must be at least 6 characters long.',
          isError: true,
        );
        return;
      }

      // Check if the email belongs to admin or lecturer domains
      if (email.endsWith('@adminhlms.com') ||
          email.endsWith('@lecturerhlms.com')) {
        _showSnackBar(
          'Admin or lecturer emails cannot be used for student sign-up.',
          isError: true,
        );
        return;
      }

      // Sign up as a student
      await _authService.signUp(email, password, 'student', username: username);

      // Show success SnackBar
      _showSnackBar('Sign-up successful! Please log in.', isError: false);

      // Navigate to the login page
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Allow SnackBar to be visible
      Navigator.pushReplacementNamed(context, Routes.login);
    } catch (e) {
      // Handle specific Firebase errors
      String errorMessage = 'Sign-up failed. Please try again.';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Use at least 6 characters.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = 'Sign-up failed: ${e.toString()}';
      }
      _showSnackBar(errorMessage, isError: true);
    } finally {
      setState(() => isLoading = false);
      _passwordController.clear();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
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
            isError
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981), // Red for error, green for success
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.06,
                vertical: constraints.maxHeight * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: constraints.maxHeight * 0.03),
                  Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.01),
                  Text(
                    'Create a student account to start learning',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.04),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Color(0xFF4B5563)),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email, color: Color(0xFF4B5563)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF4B5563),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF4B5563),
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    obscureText: _obscureText,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.04),
                  Center(
                    // Added to center the button
                    child: CustomButton(
                      text: 'Sign Up',
                      onPressed: () => _signUp(), // Button always enabled
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Center(
                    // Added to center the TextButton
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.login);
                      },
                      child: const Text(
                        'Already have an account? Login',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
