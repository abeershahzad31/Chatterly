import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallTab extends StatelessWidget {
  final String currentUserId;
  const CallTab({super.key, required this.currentUserId});

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
                  .where(FieldPath.documentId, isNotEqualTo: currentUserId) // exclude self
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData =
                        users[index].data() as Map<String, dynamic>;

                    final String username = userData['username'] ?? "Unknown";
                    final String imageUrl = (userData['imageUrl'] ?? '').toString();

                    return _buildCallItem(
                      imageUrl: imageUrl,
                      name: username,
                      time: "Available", // ✅ for now static (you can replace with last seen / recent call)
                      isMissed: false,
                      isVideo: false,
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

  /// 🔹 Custom call tile
  Widget _buildCallItem({
    required String imageUrl,
    required String name,
    required String time,
    bool isMissed = false,
    bool isVideo = false,
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
          Icon(Icons.call, color: Colors.black38, size: 22),
          const SizedBox(width: 12),
          Icon(Icons.videocam, color: Colors.black38, size: 24),
        ],
      ),
    );
  }
}

