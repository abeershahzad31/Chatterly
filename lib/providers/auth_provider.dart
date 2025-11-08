import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // ---------------------------
  // 🔔 Initialize Awesome Notifications
  // ---------------------------
  Future<void> initNotifications() async {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // ---------------------------
  // 🔔 Show local notification
  // ---------------------------
  Future<void> showWelcomeNotification(String username) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: '👋 Welcome, $username!',
        body: 'Thanks for signing up!',
      ),
    );
  }

  // ---------------------------
  // Sign up user and save to Firestore
  // ---------------------------
  Future<String> signUpWithUsername(
    String email,
    String password, {
    required String username,
    String? imageUrl, // ✅ Receive image URL from Supabase
  }) async {
    try {
      // 1️⃣ Create user with Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw 'Registration failed. Please try again.';

      // 2️⃣ Save user data to Firestore (with Supabase image URL)
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'username': username.trim(),
        'email': email,
        'imageUrl': imageUrl ?? '', // ✅ Will be empty if null
        'createdAt': FieldValue.serverTimestamp(),
      });

      await showWelcomeNotification(username);
      return user.uid;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw 'This email is already registered. Try logging in.';
        case 'invalid-email':
          throw 'Please enter a valid email address.';
        case 'weak-password':
          throw 'Your password is too weak. Choose a stronger one.';
        case 'operation-not-allowed':
          throw 'Email/Password sign-in not enabled. Contact support.';
        default:
          throw 'Registration failed. Please try again later.';
      }
    } catch (e) {
      debugPrint("🔥 General Error: $e");
      throw 'Something went wrong. Please check your internet connection.';
    }
  }

  // ---------------------------
  // Wrapper for RegisterScreen
  // ---------------------------
  Future<String> register(
    String email,
    String password,
    String username, {
    String? imageUrl, // ✅ Accept image URL
  }) async {
    final uid = await signUpWithUsername(
      email,
      password,
      username: username,
      imageUrl: imageUrl,
    );
    notifyListeners();
    return uid;
  }

  // ---------------------------
  // Login
  // ---------------------------
  Future<String> login(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw 'Login failed. Please try again.';

      await showWelcomeNotification(user.email ?? 'User');
      notifyListeners();
      return user.uid;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No account found for this email. Please sign up first.';
        case 'wrong-password':
          throw 'Incorrect password. Please try again.';
        case 'invalid-email':
          throw 'The email address is badly formatted.';
        case 'user-disabled':
          throw 'This account has been disabled. Contact support.';
        default:
          throw 'Password is invalid';
      }
    } catch (e) {
      throw 'Something went wrong. Please check your connection.';
    }
  }

  // ---------------------------
  // Logout
  // ---------------------------
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ---------------------------
  // Reset password
  // ---------------------------
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ---------------------------
  // Delete guest users (optional cleanup)
  // ---------------------------
  Future<void> deleteGuestUsers() async {
    final snap = await _firestore.collection('users').get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final hasUsername =
          data.containsKey('username') &&
          (data['username'] ?? '').toString().trim().isNotEmpty;

      if (!hasUsername || data['username'] == 'guest user') {
        await doc.reference.delete();
      }
    }
  }
}
