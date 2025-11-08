import 'dart:async';
import 'dart:convert';
import 'package:chatterly/models/chat_message.dart';
import 'package:chatterly/config/fcm_config.dart';
import 'package:chatterly/services/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';





import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Extension to enable switchMap behavior on Streams
extension SwitchMapExtension<T> on Stream<T> {
  Stream<S> switchMap<S>(Stream<S> Function(T value) mapper) {
    late StreamController<S> controller;
    StreamSubscription<T>? outerSub;
    StreamSubscription<S>? innerSub;

    controller = StreamController<S>(
      onListen: () {
        outerSub = listen(
          (outerValue) async {
            await innerSub?.cancel();
            innerSub = mapper(outerValue).listen(
              controller.add,
              onError: controller.addError,
            );
          },
          onError: controller.addError,
          onDone: () async {
            await innerSub?.cancel();
            await controller.close();
          },
        );
      },
      onCancel: () async {
        await outerSub?.cancel();
        await innerSub?.cancel();
      },
    );

    return controller.stream;
  }
}

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  get isVideoCall => null;

  get currentCallId => null;

  get remoteUserId => null;

  get chatRoomId => null;

  /// Always generate consistent chatId for two users
  String generateChatId(String user1, String user2) =>
      user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';

  /// Stream all messages in a chat
  Stream<List<ChatMessage>> messagesStream(String chatId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<String> getAccessToken({
    required String clientEmail,
    required String privateKey,
    required String clientId,
  }) async {
    try {
      // Clean up the private key format
      String cleanPrivateKey = privateKey.trim();
      if (!cleanPrivateKey.startsWith('-----BEGIN PRIVATE KEY-----')) {
        throw Exception('Invalid private key format');
      }

      final accountCredentials = ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": FCMConfig.projectId,
        "private_key_id": "key_id",
        "private_key": cleanPrivateKey,
        "client_email": clientEmail,
        "client_id": clientId,
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/${Uri.encodeComponent(clientEmail)}"
      });

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      debugPrint('🔑 Attempting to get access token...');
      debugPrint('📧 Client Email: $clientEmail');
      debugPrint('🆔 Client ID: $clientId');
      debugPrint('🔑 Private Key Length: ${cleanPrivateKey.length}');
      
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final credentials = client.credentials;
      final accessToken = credentials.accessToken.data;
      
      debugPrint('✅ Access token obtained successfully');
      debugPrint('🕒 Token expires at: ${credentials.accessToken.expiry}');
      
      client.close();
      return accessToken;
    } catch (e) {
      debugPrint('❌ Failed to get access token: $e');
      debugPrint('💡 Check your Firebase service account credentials');
      rethrow;
    }
  }

  /// Get FCM token for a specific user
  Future<String?> getUserFcmToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['fcmToken'];
      }
      return null;
    } catch (e) {
      debugPrint("❌ Failed to get FCM token for user $userId: $e");
      return null;
    }
  }

  /// Get user name for personalized notifications
  Future<String?> getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['username'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      debugPrint("❌ Failed to get username for user $userId: $e");
      return 'Unknown User';
    }
  }

  /// Send call notification
  Future<void> sendCallNotification({
    required String projectId,
    required String clientEmail,
    required String privateKey,
    required String targetUserId,
    required String callerId,
    required bool isVideoCall, required String callId,
  }) async {
    try {
      // Validate FCM configuration
      if (!_isValidFCMConfig(projectId, clientEmail, privateKey)) {
        debugPrint("❌ Invalid FCM configuration detected");
        debugPrint("💡 Using demo credentials - notifications will not work");
        debugPrint("💡 Please update lib/config/fcm_config.dart with your actual Firebase credentials");
        return;
      }

      final targetToken = await getUserFcmToken(targetUserId);
      if (targetToken == null) {
        debugPrint("❌ No FCM token found for user: $targetUserId");
        debugPrint("💡 Make sure the target user has logged in and FCM token is saved");
        return;
      }

      debugPrint("🔍 Target FCM Token: $targetToken");
      debugPrint("🔍 Target User ID: $targetUserId");

      final callerName = await getUserName(callerId);
      debugPrint("🔍 Caller Name: $callerName");
      
      debugPrint("🔑 Getting access token for FCM...");
      final accessToken = await getAccessToken(
        clientEmail: clientEmail,
        privateKey: privateKey,
        clientId: FCMConfig.clientId,
      );
      debugPrint("✅ Access token obtained: ${accessToken.substring(0, 20)}...");
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "message": {
            "token": targetToken,
            "notification": {
              "title": isVideoCall ? "📹 Incoming Video Call" : "📞 Incoming Call",
              "body": "$callerName is calling you..."
            },
            "data": {
              "type": "call",
              "callerId": callerId,
              "isVideo": isVideoCall.toString(),
              "callId": generateChatId(callerId, targetUserId),
            }
          }
        }),
      );

      debugPrint("📞 Call notification sent. Response: ${response.body}");

      if (response.statusCode != 200) {
        debugPrint("❌ FCM request failed with status: ${response.statusCode}");
        debugPrint("❌ Response body: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Failed to send call notification: $e");
    }
  }

  /// Send message notification
  Future<void> sendMessageNotification({
    required String projectId,
    required String clientEmail,
    required String privateKey,
    required String targetUserId,
    required String senderId,
    required String messageText,
  }) async {
    try {
      final targetToken = await getUserFcmToken(targetUserId);
      if (targetToken == null) {
        debugPrint("❌ No FCM token found for user: $targetUserId");
        return;
      }

      final senderName = await getUserName(senderId);
      final accessToken = await getAccessToken(
        clientEmail: clientEmail,
        privateKey: privateKey,
        clientId: FCMConfig.clientId,
      );

      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // Determine message type and format using contains (handles ?t= query params)
      String notificationBody;
      final lower = messageText.toLowerCase();
      if (lower.startsWith("http")) {
        if (lower.contains(".jpg") ||
            lower.contains(".jpeg") ||
            lower.contains(".png") ||
            lower.contains(".webp") ||
            lower.contains(".gif")) {
          notificationBody = "📷 $senderName sent a photo";
        } else if (lower.contains(".pdf") ||
            lower.contains(".doc") ||
            lower.contains(".docx") ||
            lower.contains(".ppt") ||
            lower.contains(".pptx") ||
            lower.contains(".xls") ||
            lower.contains(".xlsx")) {
          notificationBody = "📄 $senderName sent a document";
        } else if (lower.contains(".mp3") ||
            lower.contains(".m4a") ||
            lower.contains(".wav") ||
            lower.contains(".aac") ||
            lower.contains(".ogg")) {
          notificationBody = "🎤 $senderName sent a voice message";
        } else {
          notificationBody = "🔗 $senderName sent a file";
        }
      } else {
        // Truncate long messages
        final truncatedText = messageText.length > 50
            ? "${messageText.substring(0, 50)}..."
            : messageText;
        notificationBody = "$senderName: $truncatedText";
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "message": {
            "token": targetToken,
            "notification": {
              "title": "💬 New Message",
              "body": notificationBody,
            },
            "data": {
              "type": "message",
              "senderId": senderId,
              "chatId": generateChatId(senderId, targetUserId),
              "messageText": messageText,
            }
          }
        }),
      );

      debugPrint("💬 Message notification sent. Response: ${response.body}");
    } catch (e) {
      debugPrint("❌ Failed to send message notification: $e");
    }
  }

  /// Legacy method for backward compatibility
  Future<void> sendPushMessage({
    required String projectId,
    required String clientEmail,
    required String privateKey,
    required String targetToken, // FCM token of receiver device
  }) async {
    final accessToken = await getAccessToken(
      clientEmail: clientEmail,
      privateKey: privateKey,
      clientId: FCMConfig.clientId,
    );

    final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "message": {
          "token": targetToken,
          "notification": {
            "title": "Incoming Call",
            "body": "Someone is calling you..."
          },
          "data": {
            "type": "call",
            "callerId": "test_user"
          }
        }
      }),
    );

    debugPrint("FCM response: ${response.body}");
  }

  /// Send a message (text / image / voice / document)
  Future<void> sendMessage({
    required String receiverId,
    required String text, // plain text OR Supabase URL
    required String chatId,
    required imageUrl,
    // Optional notification parameters
    String? projectId,
    String? clientEmail,
    String? privateKey,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint("❌ No current user found.");
        return;
      }

      debugPrint("✉️ sendMessage called. chatId=$chatId, receiverId=$receiverId");
      debugPrint(
          "✉️ text (truncated): ${text.length > 200 ? text.substring(0, 200) + '...' : text}");

      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = chatRef.collection('messages').doc();

      final timestamp = FieldValue.serverTimestamp();
      final trimmedText = text.trim();

      // helpers (use contains to handle query params)
      bool _isImageUrl(String url) {
        final lower = url.toLowerCase();
        return lower.startsWith('http') &&
            (lower.contains('.jpg') ||
                lower.contains('.jpeg') ||
                lower.contains('.png') ||
                lower.contains('.gif') ||
                lower.contains('.webp'));
      }

      bool _isDocumentUrl(String url) {
        final lower = url.toLowerCase();
        return lower.startsWith('http') &&
            (lower.contains('.pdf') ||
                lower.contains('.doc') ||
                lower.contains('.docx') ||
                lower.contains('.ppt') ||
                lower.contains('.pptx') ||
                lower.contains('.xls') ||
                lower.contains('.xlsx') ||
                lower.contains('.txt'));
      }

      bool _isVoiceUrl(String url) {
        final lower = url.toLowerCase();
        return lower.startsWith('http') &&
            (lower.contains('.mp3') ||
                lower.contains('.m4a') ||
                lower.contains('.wav') ||
                lower.contains('.aac') ||
                lower.contains('.ogg'));
      }

      String type = 'text';
      if (_isImageUrl(trimmedText)) {
        type = 'image';
      } else if (_isDocumentUrl(trimmedText)) {
        type = 'document';
      } else if (_isVoiceUrl(trimmedText)) {
        type = 'voice';
      }

      final messageData = {
        'id': messageRef.id,
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'text': trimmedText,
        'timestamp': timestamp,
        'type': type,
      };

      final batch = _firestore.batch();
      batch.set(messageRef, messageData);

      // Build a friendly lastMessage string for chat doc (detect types robustly)
      String computeLastMessagePreview(String txt) {
        if (_isImageUrl(txt)) return "📷 Image";
        if (_isDocumentUrl(txt)) return "📄 Document";
        if (_isVoiceUrl(txt)) return "🎤 Voice message";
        final preview = txt.length > 60 ? "${txt.substring(0, 60)}..." : txt;
        return preview;
      }

      batch.set(
        chatRef,
        {
          'users': FieldValue.arrayUnion([currentUser.uid, receiverId]),
          'lastMessage': computeLastMessagePreview(trimmedText),
          'timestamp': timestamp,
          // optional participants array (useful for rules)
          'participants': FieldValue.arrayUnion([currentUser.uid, receiverId]),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint(
          "✅ Message written to Firestore (messageId=${messageRef.id}, type=$type)");

      // Send push notification if credentials are provided
      if (projectId != null && clientEmail != null && privateKey != null) {
        await sendMessageNotification(
          projectId: projectId,
          clientEmail: clientEmail,
          privateKey: privateKey,
          targetUserId: receiverId,
          senderId: currentUser.uid,
          messageText: trimmedText,
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Failed to send message: $e");
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  /// Edit a message
  Future<void> editMessage(String chatId, String messageId, String newText) async {
    try {
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(messageId)
          .update({'text': newText.trim()});
      debugPrint("✏️ Message edited: $messageId");
    } catch (e) {
      debugPrint("❌ Failed to edit message: $e");
    }
  }

  /// Delete message for everyone (replace text)
  Future<void> deleteForEveryone(String chatId, String messageId) async {
    try {
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(messageId)
          .update({'text': "🚫 This message was deleted"});
      debugPrint("🗑️ Message deleted for everyone: $messageId");
    } catch (e) {
      debugPrint("❌ Failed to delete for everyone: $e");
    }
  }

  /// Delete message only for current user
  Future<void> deleteMessageForMe(String chatId, String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(messageId)
          .delete();

      debugPrint("🗑️ Message deleted for me only: $messageId");
    } catch (e) {
      debugPrint("❌ Failed to delete message for me: $e");
    }
  }

  /// Save FCM token for push notifications
  Future<void> saveFcmToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await FCMService.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ FCM token saved: $token");
    } else {
      debugPrint("❌ Failed to get FCM token");
    }
  }

  /// Debug method to check FCM token status
  Future<void> debugFcmTokenStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final fcmToken = data['fcmToken'];
        final username = data['username'] ?? 'Unknown';

        debugPrint("🔍 User: $username (ID: $userId)");
        debugPrint("🔍 FCM Token: ${fcmToken ?? 'NOT FOUND'}");

        if (fcmToken == null) {
          debugPrint("❌ This user has no FCM token stored!");
          debugPrint("💡 User needs to log in and call saveFcmToken()");
        }
      } else {
        debugPrint("❌ User document not found: $userId");
      }
    } catch (e) {
      debugPrint("❌ Error checking FCM token status: $e");
    }
  }

  /// Validate FCM configuration
  bool _isValidFCMConfig(String projectId, String clientEmail, String privateKey) {
    // Check if using demo/placeholder credentials
    if (projectId == 'chatterly-9b2d2' && 
        clientEmail == 'firebase-adminsdk-fbsvc@chatterly-9b2d2.iam.gserviceaccount.com') {
      return false;
    }
    
    // Check if private key is properly formatted
    if (!privateKey.contains('-----BEGIN PRIVATE KEY-----') || 
        !privateKey.contains('-----END PRIVATE KEY-----')) {
      return false;
    }
    
    return true;
  }

  void endCall() {}
}
