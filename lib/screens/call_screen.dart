import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../call_page.dart';
import '../providers/chat_provider.dart';
import '../config/fcm_config.dart';

class CallTab extends StatelessWidget {
  final String currentUserId;
  const CallTab({super.key, required this.currentUserId});

  /// 🔹 Generate consistent chatId between 2 users (same for caller & callee)
  String _generateChatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join("_");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              "Recent",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('username')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != currentUserId)
                    .toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      "No recent calls",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final String username = data['username'] ?? "Unknown";
                    final String imageUrl = (data['imageUrl'] ?? '').toString();

                    String time = "Today, 09:30 AM"; // fake timestamp for now
                    final chatId = _generateChatId(currentUserId, user.id);

                    return _buildCallItem(
                      context: context,
                      imageUrl: imageUrl,
                      name: username,
                      time: time,
                      targetUserId: user.id, // ✅ pass receiver’s id
                      chatId: chatId,
                      isMissed: index % 3 == 0,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Single Call Tile
  Widget _buildCallItem({
    required BuildContext context,
    required String imageUrl,
    required String name,
    required String time,
    required String targetUserId, // ✅ the person you want to call
    required String chatId,
    bool isMissed = false,
    bool isGroup = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        backgroundColor: Colors.grey.shade300,
        child: imageUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.black54)
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          fontSize: 13,
          color: isMissed ? Colors.red : Colors.black54,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 📞 Audio Call Button
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green, size: 22),
            onPressed: () async {
              final chatProvider =
                  Provider.of<ChatProvider>(context, listen: false);

              // ✅ Send notification to target user
              await chatProvider.sendCallNotification(
                projectId: FCMConfig.projectId,
                clientEmail: FCMConfig.clientEmail,
                privateKey: FCMConfig.privateKey,
                targetUserId: targetUserId,
                callerId: currentUserId,
                isVideoCall: false,
                callId: chatId, // ✅ keep same callId for both
              );

              // ✅ Navigate caller to CallPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallPage(
                  
                    callID: chatId,
                    isVideo: false,
                  ),
                ),
              );
            },
          ),

          /// 🎥 Video Call Button
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.blue, size: 24),
            onPressed: () async {
              final chatProvider =
                  Provider.of<ChatProvider>(context, listen: false);

              await chatProvider.sendCallNotification(
                projectId: FCMConfig.projectId,
                clientEmail: FCMConfig.clientEmail,
                privateKey: FCMConfig.privateKey,
                targetUserId: targetUserId,
                callerId: currentUserId,
                isVideoCall: true,
                callId: chatId,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallPage(
                  
                    callID: chatId,
                    isVideo: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
