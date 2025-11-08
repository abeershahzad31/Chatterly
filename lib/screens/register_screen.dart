import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../widgets/common_textfield.dart';
import '../widgets/common_button.dart';
import 'UsersScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _isPasswordVisible = false;
  File? _profileImage;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_validateForm);
    _emailCtrl.addListener(_validateForm);
    _passwordCtrl.addListener(_validateForm);
    _confirmPasswordCtrl.addListener(_validateForm);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'profile_$userId.$fileExt';

      await Supabase.instance.client.storage
          .from('images')
          .upload(fileName, imageFile,
              fileOptions: const FileOptions(upsert: true));

      return Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String? profileUrl;
      final tempUserId = DateTime.now().millisecondsSinceEpoch.toString();

      if (_profileImage != null) {
        profileUrl = await _uploadProfileImage(_profileImage!, tempUserId);
      }

      final userId = await context.read<AuthProvider>().register(
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim(),
            _usernameCtrl.text.trim(),
            imageUrl: profileUrl,
          );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UsersScreen(currentUserId: userId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Registration failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _validateForm() {
    final isNameValid = _usernameCtrl.text.trim().isNotEmpty;
    final isEmailValid = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailCtrl.text.trim());
    final isPasswordValid = _passwordCtrl.text.trim().length >= 6;
    final isConfirmPasswordValid =
        _confirmPasswordCtrl.text.trim() == _passwordCtrl.text.trim() &&
            _confirmPasswordCtrl.text.isNotEmpty;

    final valid =
        isNameValid && isEmailValid && isPasswordValid && isConfirmPasswordValid;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),

                // Title
                const Text.rich(
                  TextSpan(
                    text: "Sign up with ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "Email",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Get chatting with friends and family today by\nsigning up for our chat app!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Name field
                CommonTextField(
                  controller: _usernameCtrl,
                  hintText: "Your name",
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your name' : null,
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
                      return 'Invalid email address';
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
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
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
                const SizedBox(height: 24),

                // Confirm password field
                CommonTextField(
                  controller: _confirmPasswordCtrl,
                  hintText: "Confirm Password",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 60), // space before button
              ],
            ),
          ),
        ),
      ),

      // Fixed bottom button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CommonButton(
          text: _loading ? 'Creating...' : 'Create an account',
          isLoading: _loading,
          onPressed: () {
            if (_isFormValid && !_loading) {
              _register();
            }
          },
          backgroundColor: _isFormValid ? Colors.teal : Colors.grey.shade300,
          textColor: _isFormValid ? Colors.white : Colors.black54,
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
