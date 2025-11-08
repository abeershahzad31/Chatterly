import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<String> phoneContacts = []; // device contacts
  List<DocumentSnapshot> matchedUsers = []; // Firestore matched users
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  /// Load contacts from device
  Future<void> loadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      final numbers = contacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => c.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), ''))
          .toList();

      setState(() {
        phoneContacts = numbers;
      });

      await fetchMatchedUsers();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetch users from Firestore whose phone numbers exist in phoneContacts
  Future<void> fetchMatchedUsers() async {
    if (phoneContacts.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    final users = snapshot.docs.where((doc) {
      final userData = doc.data() as Map<String, dynamic>;
      final userPhone = (userData['phone'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[^0-9+]'), '');
      return phoneContacts.contains(userPhone);
    }).toList();

    setState(() {
      matchedUsers = users;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.4),
        toolbarHeight: 100,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Contacts",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : matchedUsers.isEmpty
                ? const Center(
                    child: Text(
                      "No Chatterly friends in your contacts",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: matchedUsers.length,
                    itemBuilder: (context, index) {
                      final user =
                          matchedUsers[index].data() as Map<String, dynamic>;
                      final username = user['username'] ?? "Unknown";
                      final status =
                          user['status'] ?? "Hey there! I am using Chatterly";
                      final profileImageUrl = user['profileImageUrl'] ?? "";

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl.isEmpty
                              ? const Icon(Icons.person,
                                  size: 32, color: Colors.black54)
                              : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // ✅ Navigate to chat screen with this user
                          // Example:
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (_) => ChatScreen(
                          //       currentUserId: FirebaseAuth.instance.currentUser!.uid,
                          //       otherUserId: matchedUsers[index].id,
                          //     ),
                          //   ),
                          // );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
