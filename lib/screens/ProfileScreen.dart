import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../config/fcm_config.dart';
import '../call_page.dart';
import '../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String? username;
  final String? email;
  final String? profileImageUrl;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.username,
    this.email,
    this.profileImageUrl,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        debugPrint('📧 Firebase user data: $data');
        setState(() {
          userData = data;
          isLoading = false;
        });
      } else {
        debugPrint('❌ User document does not exist for userId: ${widget.userId}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String get displayName {
    if (userData != null) {
      return userData!['username'] ??
          userData!['name'] ??
          widget.username ??
          'Unknown User';
    }
    return widget.username ?? 'Unknown User';
  }

  String get userEmail {
    if (userData != null) {
      return userData!['email'] ?? widget.email ?? 'Not available';
    }
    return widget.email ?? 'Not available';
  }

  String get profileImage {
    if (userData != null) {
      return userData!['imageUrl'] ??
          userData!['profileImageUrl'] ??
          widget.profileImageUrl ??
          '';
    }
    return widget.profileImageUrl ?? '';
  }

  String get phoneNumber {
    if (userData != null) {
      return userData!['phone'] ?? 'Not available';
    }
    return 'Not available';
  }

  String get about {
    if (userData != null) {
      return userData!['about'] ?? 'Hey there, I’m using Chatterly';
    }
    return 'Hey there, I’m using Chatterly';
  }

  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = _generateChatId(currentUser.uid, widget.userId);

    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {
        'chatId': chatId,
        'receiverId': widget.userId,
        'receiverName': displayName,
        'receiverPic': profileImage,
      },
    );
  }

  Future<void> _makeAudioCall() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = _generateChatId(currentUser.uid, widget.userId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(callID: chatId, isVideo: false),
      ),
    );

    _sendCallNotificationInBackground(chatId, false);
  }

  Future<void> _makeVideoCall() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = _generateChatId(currentUser.uid, widget.userId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(callID: chatId, isVideo: true),
      ),
    );

    _sendCallNotificationInBackground(chatId, true);
  }

  String _generateChatId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }

  void _sendCallNotificationInBackground(String chatId, bool isVideo) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendCallNotification(
        projectId: FCMConfig.projectId,
        clientEmail: FCMConfig.clientEmail,
        privateKey: FCMConfig.privateKey,
        targetUserId: widget.userId,
        callerId: currentUser.uid,
        isVideoCall: isVideo,
        callId: chatId,
      );
      debugPrint('✅ Call notification sent successfully');
    } catch (e) {
      debugPrint('❌ Failed to send call notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 🔹 Top profile section (black background)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFFB74D),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage.isEmpty
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Action buttons (message / video / audio / more)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(Icons.message, _sendMessage),
                _buildActionButton(Icons.videocam, _makeVideoCall),
                _buildActionButton(Icons.phone, _makeAudioCall),
                _buildActionButton(Icons.more_horiz, () {}),
              ],
            ),
          ),

          // 🔹 White info section
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    _buildInfo("Display Name", displayName),
                    const SizedBox(height: 20),
                    _buildInfo("Email Address", userEmail), // ✅ email now shows
                    const SizedBox(height: 20),
                    _buildInfo("About", about),
                    const SizedBox(height: 20),
                    _buildInfo("Phone Number", phoneNumber),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey.shade900,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildInfo(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}


