import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_button.dart';
import '../routes.dart';
import '../widgets/loading_indicator.dart';
import '../models/interaction.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true;

  Future<void> _signIn() async {
    setState(() => isLoading = true);
    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        final role = await _authService.getUserRole(user.uid);
        final email = _emailController.text.trim().toLowerCase();

        // Log login interaction
        final interaction = Interaction(
          userId: user.uid,
          action: 'login',
          details: 'User logged in: $email',
          timestamp: Timestamp.now(),
        );
        await _firestoreService.logInteraction(interaction);

        if (email.endsWith('@adminhlms.com') && role == 'admin') {
          Navigator.pushReplacementNamed(context, Routes.adminDashboard);
        } else if (email.endsWith('@lecturerhlms.com') && role == 'lecturer') {
          Navigator.pushReplacementNamed(context, Routes.lecturerDashboard);
        } else if (role == 'student' || role == null) {
          Navigator.pushReplacementNamed(context, Routes.dashboard);
        } else {
          _showSnackBar('Login failed');
          _passwordController.clear();
        }
      } else {
        _showSnackBar('Login failed');
        _passwordController.clear();
      }
    } catch (e) {
      _showSnackBar('Login failed');
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
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.01),
                  Text(
                    'Login to continue learning',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.04),
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
                      : Center(
                        child: CustomButton(
                          text: 'Login',
                          onPressed: _signIn,
                          //width: constraints.maxWidth * 0.6,
                        ),
                      ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.signup);
                      },
                      child: const Text(
                        'Don\'t have an account? Sign Up',
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
