import 'dart:io';
import 'package:chatterly/screens/UsersScreen.dart';
import 'package:chatterly/screens/NotificationsScreen.dart'; // ✅ Import Notifications Screen
import 'package:chatterly/supabase_service.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  final String currentUserId;
  const SettingsScreen({super.key, required this.currentUserId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _isUploading = false;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        userData = userDoc.data();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || currentUser == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 75);
    if (pickedFile != null) {
      setState(() => _isUploading = true);

      File file = File(pickedFile.path);

      final imageUrl =
          await _supabaseService.uploadProfileImage(file, currentUser!.uid);

      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'profileImageUrl': imageUrl});

        setState(() {
          userData?['profileImageUrl'] = imageUrl;
        });
      }

      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.4),
        toolbarHeight: 120,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UsersScreen(
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),  
                  topRight: Radius.circular(20), 
                ),
              ),
              child: Column(
                children: [
                  // ✅ Profile Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: (userData?['profileImageUrl'] !=
                                            null &&
                                        userData!['profileImageUrl']
                                            .toString()
                                            .isNotEmpty)
                                    ? NetworkImage(userData!['profileImageUrl'])
                                    : null,
                                child: (userData?['profileImageUrl'] == null ||
                                        userData!['profileImageUrl']
                                            .toString()
                                            .isEmpty)
                                    ? const Icon(Icons.person,
                                        size: 50, color: Colors.black54)
                                    : null,
                              ),
                              if (_isUploading)
                                const Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData?['username'] ??
                                    currentUser?.displayName ??
                                    "Username",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userData?['status'] ??
                                    "Hey there! I am using Chatterly",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // ✅ Options list
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildAssetTile(
                          "assets/accounts.png",
                          "Account",
                          "Privacy, security, change number",
                        ),
                        _buildAssetTile(
                          "assets/chats.png",
                          "Chat",
                          "Chat history, theme, wallpapers",
                        ),
                        _buildAssetTile(
                          "assets/notifications.png",
                          "Notifications",
                          "Messages, group and others",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationsScreen(
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildAssetTile(
                          "assets/friends.png",
                          "Invite a friend",
                          "",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ✅ Modified Tile with onTap support
  Widget _buildAssetTile(String asset, String title, String subtitle,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Image.asset(
        asset,
        height: 42,
        width: 42,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      onTap: onTap,
    );
  }
}
