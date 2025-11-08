import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SettingsScreen.dart';
import 'forgot_password_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String currentUserId;

  const PersonalDetailsScreen({super.key, required this.currentUserId});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  bool _isLoading = false;
  static const Color backgroundColor = Color(0xFF0B1E40);
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _usernameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// ✅ Show edit username dialog and save to Firestore
  Future<void> _showEditUsernameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController controller =
        TextEditingController(text: user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit Username",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter new username",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && user != null) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  // ✅ Update Firebase Auth
                  await user.updateDisplayName(newName);
                  await user.reload();

                  // ✅ Update Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'username': newName});

                  setState(() => _usernameController.text = newName);
                } catch (e) {
                  // Handle error if needed
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Color(0xFF0B1E40)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SettingsScreen(currentUserId: widget.currentUserId),
              ),
            );
          },
        ),
        title: const Text(
          "Personal Details",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  /// Username with edit option
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: const Text(
                      "Username",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      _usernameController.text.isNotEmpty
                          ? _usernameController.text
                          : "No Name",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: _showEditUsernameDialog,
                    ),
                  ),
                  const Divider(color: Colors.white30, height: 1),

                  /// Email (read-only)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: const Text(
                      "Email",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      user?.email ?? "email",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const Divider(color: Colors.white30, height: 1),

                  /// Password / Forgot Password
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: const Text(
                      "Password",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: const Text(
                      "********",
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white30, height: 1),
                ],
              ),
            ),
    );
  }
}


