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
    setState(() => isLoading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final username = _usernameController.text.trim();

      // Check if the email belongs to admin or lecturer domains
      if (email.endsWith('@adminhlms.com') ||
          email.endsWith('@lecturerhlms.com')) {
        _showSnackBar('Sign-up failed');
        _passwordController.clear();
        return;
      }

      // Validate username
      if (username.isEmpty) {
        _showSnackBar('Sign-up failed');
        _passwordController.clear();
        return;
      }

      // Sign up as a student
      await _authService.signUp(
        email,
        _passwordController.text.trim(),
        'student',
        username: username,
      );

      // Navigate to the student dashboard
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } catch (e) {
      _showSnackBar('Sign-up failed');
      _passwordController.clear();
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // Red for error
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
                  isLoading
                      ? const LoadingIndicator()
                      : CustomButton(text: 'Sign Up', onPressed: _signUp),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Center(
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
