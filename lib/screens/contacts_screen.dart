import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart'; // for firstWhereOrNull

import 'chat_screen.dart';

class SystemContactsScreen extends StatefulWidget {
  const SystemContactsScreen({super.key});

  @override
  State<SystemContactsScreen> createState() => _SystemContactsScreenState();
}

class _SystemContactsScreenState extends State<SystemContactsScreen> {
  List<Contact> phoneContacts = []; // device contacts
  List<DocumentSnapshot<Map<String, dynamic>>> matchedUsers = []; // Firestore matched users
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      loadContacts();
    });
  }

  /// Load contacts from device
  Future<void> loadContacts() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts =
            await FlutterContacts.getContacts(withProperties: true);

        final filtered = contacts.where((c) => c.phones.isNotEmpty).toList();

        filtered.sort((a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

        setState(() {
          phoneContacts = filtered;
        });

        await fetchMatchedUsers();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading contacts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetch users from Firestore whose phone numbers exist in phoneContacts
  Future<void> fetchMatchedUsers() async {
    try {
      if (phoneContacts.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final numbers = phoneContacts
          .map((c) => c.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), ''))
          .toList();

      final users = snapshot.docs.where((doc) {
        final userData = doc.data();
        final userPhone = (userData['phone'] ?? '')
            .toString()
            .replaceAll(RegExp(r'[^0-9+]'), '');
        return numbers.contains(userPhone);
      }).toList();

      setState(() {
        matchedUsers = users;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching matched users: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Create or open a chat room with the selected user
  Future<void> openChatRoom(String number, String name) async {
    try {
      final matched = matchedUsers.firstWhereOrNull((doc) {
        final userData = doc.data();
        if (userData == null) return false;
        final userPhone = (userData['phone'] ?? '')
            .toString()
            .replaceAll(RegExp(r'[^0-9+]'), '');
        return number.replaceAll(RegExp(r'[^0-9+]'), '') == userPhone;
      });

      if (matched != null) {
        final userData = matched.data()!;
        final currentUserId = FirebaseAuth.instance.currentUser!.uid;
        final otherUserId = matched.id;

        final chatRoomId = currentUserId.hashCode <= otherUserId.hashCode
            ? '${currentUserId}_$otherUserId'
            : '${otherUserId}_$currentUserId';

        final chatRoomRef =
            FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);

        final chatRoomDoc = await chatRoomRef.get();
        if (!chatRoomDoc.exists) {
          await chatRoomRef.set({
            'users': [currentUserId, otherUserId],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatRoomId,
              receiverId: otherUserId,
              receiverName: userData['name'] ?? 'Unknown',
              receiverPic: userData['profilePic'] ?? '',
              chatId: chatRoomId,
              otherUser: userData, // Firestore user data
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not registered in app")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error opening chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ consistent background
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : phoneContacts.isEmpty
              ? const Center(
                  child: Text(
                    "No contacts found",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: phoneContacts.length,
                  itemBuilder: (context, index) {
                    final contact = phoneContacts[index];
                    final name = contact.displayName.isNotEmpty
                        ? contact.displayName
                        : "Unknown";
                    final number =
                        contact.phones.isNotEmpty ? contact.phones.first.number : "No Number";

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey.shade300,
                        child: name.isNotEmpty
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => openChatRoom(number, name),
                    );
                  },
                ),
    );
  }
}
