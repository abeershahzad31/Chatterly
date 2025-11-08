import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../routes/app_routes.dart';
import '../navigation_service.dart';

/// 🔹 Top-level background handler (must be outside the class)
@pragma('vm:entry-point') // Required for background isolate
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 Background FCM received: ${message.data}");
  await FCMService.handleMessage(message, source: "background");
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM service
  static Future<void> initialize() async {
    await _requestPermission();
    await _configureNotificationChannels();
    await _setupMessageHandlers();
    debugPrint("✅ FCMService initialized");
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 FCM Permission: ${settings.authorizationStatus}');
  }

  /// Configure notification channels for Awesome Notifications
  static Future<void> _configureNotificationChannels() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'chat_channel',
          channelName: 'Chat Notifications',
          channelDescription: 'Notification channel for chat messages',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'call_channel',
          channelName: 'Call Notifications',
          channelDescription: 'Notification channel for incoming calls',
          defaultColor: Colors.green,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: true,
    );
  }

  /// Setup message handlers for all app states
  static Future<void> _setupMessageHandlers() async {
    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      handleMessage(message, source: "foreground");
    });

    // When tapping a notification (background → open app)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message, source: "onMessageOpenedApp");
    });

    // App was terminated
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage, source: "terminated");
    }
  }

  /// Common handler for all states
  static Future<void> handleMessage(RemoteMessage message, {String source = ""}) async {
    debugPrint('📱 [$source] Message received: ${message.data}');
    final data = message.data;

    if (data['type'] == 'call') {
      await _showCallNotification(message);
    } else if (data['type'] == 'message') {
      await _showMessageNotification(message);
    }
  }

  /// Show call notification
  static Future<void> _showCallNotification(RemoteMessage message) async {
    final data = message.data;
    final callerId = data['callerId'] ?? 'Unknown';
    final isVideo = data['isVideo'] == 'true';
    final callId = data['callId'] ?? '';

    debugPrint("📞 Incoming call -> callerId: $callerId | callId: $callId | isVideo: $isVideo");

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'call_channel',
        title: isVideo ? '📹 Incoming Video Call' : '📞 Incoming Call',
        body: '$callerId is calling you...',
        category: NotificationCategory.Call,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        payload: {
          'type': 'call',
          'callerId': callerId,
          'callId': callId,
          'isVideo': isVideo.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'accept_call',
          label: 'Accept',
          color: Colors.green,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'decline_call',
          label: 'Decline',
          color: Colors.red,
          autoDismissible: true,
        ),
      ],
    );
  }

  /// Show chat message notification
  static Future<void> _showMessageNotification(RemoteMessage message) async {
    final data = message.data;
    final messageText = data['messageText'] ?? '';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'chat_channel',
        title: '💬 New Message',
        body: messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText,
        payload: {
          'type': 'message',
          'chatId': data['chatId'] ?? '',
          'senderId': data['senderId'] ?? '',
        },
      ),
    );
  }

  /// Setup notification action listeners
  static void setupNotificationActions() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (receivedAction) async {
        final payload = receivedAction.payload ?? {};
        final actionKey = receivedAction.buttonKeyPressed;

        debugPrint('🔔 Action: $actionKey | Payload: $payload');

        if (payload['type'] == 'call') {
          await _handleCallAction(actionKey, payload);
        } else if (payload['type'] == 'message') {
          await _handleMessageAction(payload);
        }
      },
    );
  }

  /// Handle call actions (Accept / Decline)
  static Future<void> _handleCallAction(String? actionKey, Map<String, String?> payload) async {
    String callerId = (payload['callerId'] ?? '').toString();
    String callId = (payload['callId'] ?? '').toString();
    final bool isVideo = (payload['isVideo'] ?? 'false') == 'true';

    debugPrint("🎬 Handling call action: $actionKey | callerId: $callerId | callId: $callId | isVideo: $isVideo");

    if (actionKey == 'accept_call') {
      debugPrint('✅ User accepted call');
      await _joinCall(callerId, callId, isVideo);
    } else if (actionKey == 'decline_call') {
      debugPrint('❌ User declined call');
      await _declineCall(callerId, callId);
    }
  }

  /// Handle message action
  static Future<void> _handleMessageAction(Map<String, String?> payload) async {
    debugPrint('💬 Open chat: ${payload['chatId']}');
    // TODO: Navigate to chat screen
  }

  /// Join call
  static Future<void> _joinCall(String callerId, String callId, bool isVideo) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint("❌ No logged in user, cannot join call");
        return;
      }

      if (callId.isEmpty) {
        debugPrint('❌ Missing callId in payload');
        return;
      }

      debugPrint('🎥 Joining call: $callId (Video: $isVideo) | callerId: $callerId');

      NavigationService.navigatorKey.currentState?.pushNamed(
        AppRoutes.call,
        arguments: {
          'callerId': callerId,
          'callId': callId,
          'isVideo': isVideo,
        },
      );
    } catch (e) {
      debugPrint('❌ Join call error: $e');
    }
  }

  /// Decline call
  static Future<void> _declineCall(String callerId, String callId) async {
    debugPrint('📞 Call declined: $callId (caller: $callerId)');
    // TODO: Notify caller through Firestore or FCM
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint("📡 FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint('❌ Token error: $e');
      return null;
    }
  }
}


