import 'package:chatterly/screens/UsersScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../widgets/common_textfield.dart';
import '../widgets/common_button.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _isPasswordVisible = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();

    // ✅ Removed _checkLoginStatus()

    _emailCtrl.addListener(_validateForm);
    _passwordCtrl.addListener(_validateForm);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      String userId = await context.read<AuthProvider>().login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim(),
          );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UsersScreen(currentUserId: userId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _validateForm() {
    final isEmailValid = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailCtrl.text.trim());
    final isPasswordValid = _passwordCtrl.text.trim().length >= 6;

    final valid = isEmailValid && isPasswordValid;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Title
                const Text(
                  "Log in to Chatbox",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Welcome back! Sign in using your social\naccount or email to continue us",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),

                // Social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton("assets/facebook.png", size: 38),
                    const SizedBox(width: 20),
                    _socialButton("assets/google.png", size: 28),
                    const SizedBox(width: 20),
                    _socialButton("assets/apple.png", size: 28),
                  ],
                ),
                const SizedBox(height: 24),

                // Divider with OR
                Row(
                  children: const [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // Email field
                CommonTextField(
                  controller: _emailCtrl,
                  hintText: "Your email",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password field
                CommonTextField(
                  controller: _passwordCtrl,
                  hintText: "Password",
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 60),

                // Login button
                CommonButton(
                  text: _loading ? 'Logging in...' : 'Log in',
                  isLoading: _loading,
                  onPressed: () {
                    if (_isFormValid && !_loading) {
                      _login();
                    }
                  },
                  backgroundColor:
                      _isFormValid ? Colors.teal : Colors.grey.shade300,
                  textColor: _isFormValid ? Colors.white : Colors.black54,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                const SizedBox(height: 16),

                // Forgot password
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String assetPath,
      {double size = 28, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        child: Image.asset(
          assetPath,
          height: size,
          width: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

