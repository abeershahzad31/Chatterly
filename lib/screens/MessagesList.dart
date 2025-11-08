import 'package:chatterly/screens/ProfileScreen.dart';
import 'package:chatterly/widgets/message_bubble.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesList extends StatelessWidget {
  final String currentUserId;
  final String chatRoomId;

  const MessagesList({
    super.key,
    required this.currentUserId,
    required this.chatRoomId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .doc(chatRoomId)
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("❌ Error loading messages"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              "No messages yet",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final data = msg.data() as Map<String, dynamic>;
            final senderId = data["senderId"] ?? "";
            final type = data["type"] ?? "text";
            final timestamp = data["timestamp"] as Timestamp?;
            final isMe = senderId == currentUserId;

            // 🟢 If message is a CALL
            if (type == "call") {
              final callType = data["callType"] ?? "audio";
              final status = data["status"] ?? "missed";

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF25D366)
                            : const Color(0xFFF1F0F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            callType == "video" ? Icons.videocam : Icons.call,
                            size: 18,
                            color: status == "missed"
                                ? Colors.red
                                : Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${status.toString().toUpperCase()} ${callType.toString().toUpperCase()} CALL",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // 🟢 Normal TEXT message
            final text = data["text"] ?? "";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(senderId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox();
                }
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;

                final username = userData?["username"] ?? "Unknown";
                final email = userData?["email"] ?? "";
                final profileImageUrl = userData?["profileImage"] ?? "";

                return GestureDetector(
                  onTap: () {
                    if (!isMe) {
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            profileImageUrl: profileImageUrl,
                            username: username,
                            email: email, userId: 'userid',
                            
                          ),
                        ),
                      );
                    }
                  },
                  child: MessageBubble(
                    messageId: msg.id,
                    chatRoomId: chatRoomId,
                    text: text,
                    isMe: isMe,
                    timestamp: timestamp,
                    bubbleColor: isMe
                        ? const Color(0xFF25D366)
                        : const Color(0xFFF1F0F5),
                    textColor: Colors.black,
                    isDocument: false,
                    isLocation: false,
                    originalText: text,
                    time: timestamp != null
                        ? TimeOfDay.fromDateTime(timestamp.toDate())
                            .format(context)
                        : "",
                    username: username,
                    email: email,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
