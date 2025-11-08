import 'package:chatterly/ai_chatbot.dart' show AIChatScreen;
import 'package:chatterly/providers/chat_provider.dart';
// ⚠️ If both files exist keep both, otherwise remove one
import 'package:chatterly/screens/ContactsScreen.dart';
import 'package:chatterly/screens/contacts_screen.dart' show SystemContactsScreen;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat_screen.dart';
import 'SettingsScreen.dart';
import 'app_bottom_nav.dart';
import 'call_tab.dart'; // ✅ Import CallTab

class UsersScreen extends StatefulWidget {
  final String currentUserId;
  const UsersScreen({super.key, required this.currentUserId});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String? profileImageUrl;
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Messages",
    "Calls",
    "Contacts",
    "Settings",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().saveFcmToken();
      }
    });
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get();
    if (doc.exists) {
      setState(() {
        profileImageUrl = doc.data()?['imageUrl'] ?? '';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: _selectedIndex == 3
          ? null
          : AppBar(
              backgroundColor: backgroundColor,
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.4),
              toolbarHeight: _selectedIndex == 2 ? 95 : 80,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 28),
                onPressed: () {},
              ),
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              actions: [
                if (_selectedIndex != 3)
                  IconButton(
                    icon: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      backgroundImage: (profileImageUrl != null &&
                              profileImageUrl!.isNotEmpty)
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child: (profileImageUrl == null ||
                              profileImageUrl!.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    onPressed: () => setState(() => _selectedIndex = 3),
                  ),
              ],
            ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Messages
          Column(
            children: [
              _buildUsersRow(),
              Expanded(child: _buildMessagesList()),
            ],
          ),

          // Calls
          CallTab(currentUserId: widget.currentUserId),

          // Contacts
          SystemContactsScreen(),

          // Settings
          SettingsScreen(currentUserId: widget.currentUserId),
        ],
      ),

      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  /// 🔹 Top row avatars
  Widget _buildUsersRow() {
    return SizedBox(
      height: 95,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs
                  .where((doc) => doc.id != widget.currentUserId)
                  .toList() ??
              [];

          users.sort((a, b) {
            final aName = (a.data() as Map<String, dynamic>)['username'] ?? '';
            final bName = (b.data() as Map<String, dynamic>)['username'] ?? '';
            return aName.toLowerCase().compareTo(bName.toLowerCase());
          });

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final String imageUrl = (data['imageUrl'] ?? '').toString();
              final String username = data['username'] ?? 'Unknown';
              final String otherUserId = user.id;

              return GestureDetector(
                onTap: () async {
                  final chatId =
                      _generateChatId(widget.currentUserId, otherUserId);
                  await _createChatRoomIfNotExists(
                      chatId, widget.currentUserId, otherUserId);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        chatRoomId: chatId,
                        receiverId: otherUserId,
                        receiverName: username,
                        receiverPic: imageUrl,
                        otherUser: data,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.person, size: 28)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 60,
                        child: Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔹 Messages list
  Widget _buildMessagesList() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs
                  .where((doc) => doc.id != widget.currentUserId)
                  .toList() ??
              [];

          users.sort((a, b) {
            final aName = (a.data() as Map<String, dynamic>)['username'] ?? '';
            final bName = (b.data() as Map<String, dynamic>)['username'] ?? '';
            return aName.toLowerCase().compareTo(bName.toLowerCase());
          });

          return _buildUserList(users);
        },
      ),
    );
  }

  /// 🔹 Contacts tab
  Widget _buildContactsList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
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
              .where((doc) => doc.id != widget.currentUserId)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text("No contacts found"));
          }

          Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var user in users) {
            final data = user.data() as Map<String, dynamic>;
            final username = (data['username'] ?? 'Unknown') as String;
            String firstLetter =
                username.isNotEmpty ? username[0].toUpperCase() : '#';
            grouped.putIfAbsent(firstLetter, () => []).add(user);
          }

          final sortedKeys = grouped.keys.toList()..sort();

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  "My Contacts",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ),
              ...sortedKeys.map((letter) {
                final letterUsers = grouped[letter]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    ...letterUsers.map((userDoc) {
                      final data = userDoc.data() as Map<String, dynamic>;
                      final username = data['username'] ?? 'Unknown';
                      final imageUrl = (data['imageUrl'] ?? '').toString();
                      final bio = data['bio'] ?? "";

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          backgroundColor: Colors.grey.shade300,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.black54)
                              : null,
                        ),
                        title: Text(username,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                        subtitle: Text(bio,
                            style: const TextStyle(color: Colors.black54)),
                        onTap: () {
                          final chatId = _generateChatId(
                              widget.currentUserId, userDoc.id);
                          _createChatRoomIfNotExists(
                              chatId, widget.currentUserId, userDoc.id);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatId,
                                chatRoomId: chatId,
                                receiverId: userDoc.id, // ✅ fixed
                                receiverName: username,
                                receiverPic: imageUrl,
                                otherUser: data,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// 🔹 User list with last message
  Widget _buildUserList(List<QueryDocumentSnapshot> users) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: users.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildChatTile(
            name: "AI Chat",
            message: "Tap to start a conversation",
            time: "now",
            imageUrl: "assets/ai_icon.png",
            isAsset: true,
            unreadCount: 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIChatScreen()),
              );
            },
          );
        }

        final user = users[index - 1];
        final data = user.data() as Map<String, dynamic>;
        final String imageUrl = (data['imageUrl'] ?? '').toString();
        final String username = data['username'] ?? 'Unknown';
        final String otherUserId = user.id;
        final chatId = _generateChatId(widget.currentUserId, otherUserId);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            String latestMessage = "No messages yet";
            String time = "—";
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final msg =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              latestMessage = msg['text'] ?? '';
              final ts = msg['timestamp'] as Timestamp?;
              if (ts != null) {
                final dt = ts.toDate();
                time = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
              }
            }

            return _buildChatTile(
              name: username,
              message: latestMessage,
              time: time,
              imageUrl: imageUrl,
              unreadCount: 0,
              onTap: () async {
                await _createChatRoomIfNotExists(
                    chatId, widget.currentUserId, otherUserId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chatId,
                      chatRoomId: chatId,
                      receiverId: otherUserId,
                      receiverName: username,
                      receiverPic: imageUrl,
                      otherUser: data,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🔹 Chat tile
  Widget _buildChatTile({
    required String name,
    required String message,
    required String time,
    required String imageUrl,
    required VoidCallback onTap,
    required int unreadCount,
    bool isAsset = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black12, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: isAsset
                  ? AssetImage(imageUrl) as ImageProvider
                  : (imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null),
              child: (!isAsset && imageUrl.isEmpty)
                  ? const Icon(Icons.person, size: 28, color: Colors.black54)
                  : null,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5)),
                  const SizedBox(height: 3),
                  Text(message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 14)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time,
                    style:
                        const TextStyle(color: Colors.black45, fontSize: 12)),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("$unreadCount",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _generateChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  Future<void> _createChatRoomIfNotExists(
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



