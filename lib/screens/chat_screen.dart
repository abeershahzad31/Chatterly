import 'dart:io';
import 'package:chatterly/call_page.dart';
import 'package:chatterly/screens/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/chat_provider.dart';
import '../supabase_service.dart';
import '../config/fcm_config.dart';
import 'MessagesList.dart';
import 'MessageInputBar.dart';
import 'AttachmentMenu.dart';
import 'VoiceInputBar.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverPic;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPic,
    required this.chatId,
    required String chatRoomId,
    required Map otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();

  String? _currentUserId;
  String? _currentUserName;
  bool _isLoading = true;
  bool _showVoiceBar = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      setState(() {
        _currentUserId = firebaseUser.uid;
        _currentUserName = firebaseUser.displayName ?? "User";
        _isLoading = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
      _currentUserName = prefs.getString('userName') ?? "User";
      _isLoading = false;
    });
  }

  /// 📩 Send text message
  Future<void> _sendTextMessage(String text) async {
    if (text.isEmpty || _currentUserId == null) return;

    await Provider.of<ChatProvider>(context, listen: false).sendMessage(
      receiverId: widget.receiverId,
      text: text,
      chatId: widget.chatId,
      imageUrl: null,
      projectId: FCMConfig.isConfigured ? FCMConfig.projectId : null,
      clientEmail: FCMConfig.isConfigured ? FCMConfig.clientEmail : null,
      privateKey: FCMConfig.isConfigured ? FCMConfig.privateKey : null,
    );
    _messageController.clear();
  }

  /// 🎤 Send voice message
  Future<void> _sendVoiceMessage(File file) async {
    try {
      final supabaseService = SupabaseService();
      final publicUrl = await supabaseService.uploadVoice(file, "voices");
      if (publicUrl == null) return;

      await Provider.of<ChatProvider>(context, listen: false).sendMessage(
        receiverId: widget.receiverId,
        text: publicUrl,
        chatId: widget.chatId,
        imageUrl: null,
        projectId: FCMConfig.isConfigured ? FCMConfig.projectId : null,
        clientEmail: FCMConfig.isConfigured ? FCMConfig.clientEmail : null,
        privateKey: FCMConfig.isConfigured ? FCMConfig.privateKey : null,
      );
    } catch (e) {
      debugPrint("❌ Voice upload error: $e");
    }
  }

  /// 📷 Send image message
  Future<void> _sendImageMessage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || _currentUserId == null) return;

    final file = File(picked.path);
    try {
      final supabaseService = SupabaseService();
      final publicUrl = await supabaseService.uploadImage(file, "images");
      if (publicUrl == null) return;

      await Provider.of<ChatProvider>(context, listen: false).sendMessage(
        receiverId: widget.receiverId,
        text: publicUrl,
        chatId: widget.chatId,
        imageUrl: null,
        projectId: FCMConfig.isConfigured ? FCMConfig.projectId : null,
        clientEmail: FCMConfig.isConfigured ? FCMConfig.clientEmail : null,
        privateKey: FCMConfig.isConfigured ? FCMConfig.privateKey : null,
      );
    } catch (e) {
      debugPrint("❌ Image upload error: $e");
    }
  }

  /// 📎 Attachment menu
  void _showAttachmentMenu() {
    if (_currentUserId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AttachmentMenu(
          onPickImage: _sendImageMessage,
          picker: _picker,
          receiverId: widget.receiverId,
          chatId: widget.chatId,
          senderId: _currentUserId!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  username: widget.receiverName,
                  email: "", // pass actual email if available
                  profileImageUrl: widget.receiverPic, userId: 'userid', 
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.receiverPic.isNotEmpty
                    ? NetworkImage(widget.receiverPic)
                    : null,
                backgroundColor: Colors.black12,
                child: widget.receiverPic.isEmpty
                    ? const Icon(Icons.person, color: Colors.black54)
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    "Active now",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // 📞 Audio call
          IconButton(
            icon: const Icon(Icons.phone_outlined,
                color: Colors.black, size: 30),
            onPressed: () async {
              if (_currentUserId == null) return;

              final chatProvider =
                  Provider.of<ChatProvider>(context, listen: false);
              await chatProvider.sendCallNotification(
                projectId: FCMConfig.projectId,
                clientEmail: FCMConfig.clientEmail,
                privateKey: FCMConfig.privateKey,
                targetUserId: widget.receiverId,
                callerId: _currentUserId!,
                isVideoCall: false,
                callId: widget.chatId,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallPage(
                    callID: widget.chatId,
                    isVideo: false,
                  ),
                ),
              );
            },
          ),
          // 🎥 Video call
          IconButton(
            icon: const Icon(Icons.videocam_outlined,
                color: Colors.black, size: 32),
            onPressed: () async {
              if (_currentUserId == null) return;

              final chatProvider =
                  Provider.of<ChatProvider>(context, listen: false);
              await chatProvider.sendCallNotification(
                projectId: FCMConfig.projectId,
                clientEmail: FCMConfig.clientEmail,
                privateKey: FCMConfig.privateKey,
                targetUserId: widget.receiverId,
                callerId: _currentUserId!,
                isVideoCall: true,
                callId: widget.chatId,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallPage(
                    callID: widget.chatId,
                    isVideo: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessagesList(
              currentUserId: _currentUserId!,
              chatRoomId: widget.chatId,
            ),
          ),
          _showVoiceBar
              ? VoiceInputBar(
                  chatRoomId: widget.chatId,
                  onSend: (file) async {
                    await _sendVoiceMessage(file);
                    setState(() => _showVoiceBar = false);
                  },
                  onCancel: () => setState(() => _showVoiceBar = false),
                )
              : MessageInputBar(
                  controller: _messageController,
                  onSend: () =>
                      _sendTextMessage(_messageController.text.trim()),
                  onAttach: _showAttachmentMenu,
                  onMicTap: () => setState(() => _showVoiceBar = true),
                  onCameraTap: () {},
                ),
        ],
      ),
    );
  }
}

