import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  String? currentUserId;
  DateTime? userCreatedAt;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      currentUserId = user.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        userCreatedAt = (data['createdAt'] as Timestamp?)?.toDate();
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error loading user: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Search Users")),
        body: const Center(
          child: Text(
            "You must be logged in to search users.",
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Search Users")),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search by name or email",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchText = value.trim().toLowerCase());
              },
            ),
          ),
          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (searchText.isEmpty)
                  ? FirebaseFirestore.instance.collection('users').snapshots()
                  : FirebaseFirestore.instance
                      .collection('users')
                      .where('keywords', arrayContains: searchText)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                // Exclude current user & filter by createdAt
                final filteredUsers = users.where((userDoc) {
                  final data = userDoc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  return userDoc.id != currentUserId &&
                      (userCreatedAt == null ||
                          (createdAt != null &&
                              createdAt.isAfter(userCreatedAt!)));
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    final userId = filteredUsers[index].id;

                    final userName = data['name'] ?? 'Unknown';
                    final userEmail = data['email'] ?? '';
                    final userPic = (data['profilePic'] != null &&
                            data['profilePic'].toString().isNotEmpty)
                        ? data['profilePic']
                        : '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userPic.isNotEmpty
                            ? NetworkImage(userPic)
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                      ),
                      title: Text(userName),
                      subtitle: Text(userEmail),
                      onTap: () async {
                        final chatId = _generateChatId(currentUserId!, userId);
                        await createOrOpenChatRoom(chatId, currentUserId!, userId);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              receiverId: userId,
                              receiverName: userName,
                              receiverPic: userPic, chatRoomId: 'chatRoomId', otherUser: {}, 
                            ),
                          ),
                        );
                      },
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

  /// Generate a unique chatId based on lexicographical order of user IDs
  String _generateChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  Future<void> createOrOpenChatRoom(
      String chatId, String currentUserId, String receiverId) async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snapshot = await chatDoc.get();

    if (!snapshot.exists) {
      await chatDoc.set({
        'chatId': chatId,
        'members': [currentUserId, receiverId],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}





