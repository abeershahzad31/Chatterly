# Complete FCM Push Notifications Setup Guide

## 🎯 **What's Implemented**

### ✅ **All App States Covered**
- **Foreground**: App is active and visible
- **Background**: App is running but not visible
- **Terminated**: App is completely closed

### ✅ **Call Notifications with Actions**
- **Accept Button**: Green button to join the call
- **Decline Button**: Red button to decline the call
- **Full-screen intent**: Shows even when device is locked
- **Critical alerts**: High priority notifications

### ✅ **Message Notifications**
- Smart content detection (text, images, voice)
- Personalized with sender names
- Direct navigation to chat

## 🚀 **How It Works**

### **1. FCM Service (`lib/services/fcm_service.dart`)**
- Handles all notification states automatically
- Creates notification channels for calls and messages
- Manages Accept/Decline actions for calls
- Provides unified token management

### **2. Main App Integration (`lib/main.dart`)**
- Initializes FCM service on app start
- Sets up notification action handlers
- Handles navigation to calls and chats

### **3. Enhanced ChatProvider**
- Uses new FCM service for token management
- Sends notifications with proper payload structure
- Includes debugging for troubleshooting

## 📱 **Notification Features**

### **Call Notifications**
```dart
// Shows with Accept/Decline buttons
{
  "title": "📞 Incoming Call" / "📹 Incoming Video Call",
  "body": "[Caller Name] is calling you...",
  "actions": ["Accept", "Decline"],
  "fullScreenIntent": true,
  "criticalAlert": true
}
```

### **Message Notifications**
```dart
// Smart content detection
{
  "title": "💬 New Message",
  "body": "[Sender]: [Message preview]",
  "type": "message"
}
```

## 🔧 **Setup Steps**

### **1. Update Your FCM Config**
Make sure your `lib/config/fcm_config.dart` has the correct credentials:

```dart
class FCMConfig {
  static const String projectId = 'chatterly-9b2d2';
  static const String clientEmail = 'firebase-adminsdk-fbsvc@chatterly-9b2d2.iam.gserviceaccount.com';
  static const String clientId = '117740884968861907813'; // Your actual client ID
  static const String privateKey = '''-----BEGIN PRIVATE KEY-----
  // Your actual private key
  -----END PRIVATE KEY-----''';
}
```

### **2. Test FCM Token Generation**
Add this to your app to test FCM tokens:

```dart
// Test FCM token generation
final token = await FCMService.getToken();
print("🔍 FCM Token: $token");
```

### **3. Save FCM Tokens**
Make sure both users have FCM tokens saved:

```dart
// Call this when users log in
await chatProvider.saveFcmToken();
```

## 🧪 **Testing Scenarios**

### **Test 1: Foreground Notifications**
1. Keep app open and visible
2. Send a message or make a call from another device
3. Should see notification with actions

### **Test 2: Background Notifications**
1. Put app in background (home button)
2. Send a message or make a call from another device
3. Should see notification in notification panel

### **Test 3: Terminated Notifications**
1. Force close the app completely
2. Send a message or make a call from another device
3. Should see notification and be able to open app

### **Test 4: Call Actions**
1. Receive a call notification
2. Tap "Accept" → Should join the call
3. Tap "Decline" → Should decline the call

## 🔍 **Debugging**

### **Check FCM Token Status**
```dart
// Debug target user's FCM token
await chatProvider.debugFcmTokenStatus('TARGET_USER_ID');
```

### **Console Logs to Look For**
```
✅ FCM token saved: [token]
🔍 Target FCM Token: [token]
🔍 Target User ID: [user_id]
📞 Call notification sent. Response: [response]
✅ Call accepted - navigating to call screen
❌ Call declined
```

### **Common Issues**

1. **"UNREGISTERED" Error**
   - Target user doesn't have FCM token
   - Solution: Call `saveFcmToken()` for target user

2. **No Notifications Received**
   - Check FCM credentials
   - Verify notification permissions
   - Test on real devices

3. **Call Actions Not Working**
   - Check notification payload structure
   - Verify route navigation
   - Test Accept/Decline buttons

## 📋 **Notification Payload Structure**

### **Call Notifications**
```json
{
  "message": {
    "token": "target_fcm_token",
    "notification": {
      "title": "📞 Incoming Call",
      "body": "John is calling you..."
    },
    "data": {
      "type": "call",
      "callerId": "caller_user_id",
      "isVideo": "false",
      "callId": "unique_call_id"
    }
  }
}
```

### **Message Notifications**
```json
{
  "message": {
    "token": "target_fcm_token",
    "notification": {
      "title": "💬 New Message",
      "body": "John: Hello there!"
    },
    "data": {
      "type": "message",
      "senderId": "sender_user_id",
      "chatId": "chat_id",
      "messageText": "Hello there!"
    }
  }
}
```

## 🎉 **Ready to Test!**

Your FCM push notification system is now complete with:

✅ **All app states covered** (foreground, background, terminated)  
✅ **Call notifications with Accept/Decline actions**  
✅ **Message notifications with smart content detection**  
✅ **Proper navigation handling**  
✅ **Comprehensive debugging tools**  

Just make sure both users have FCM tokens saved and test away! 🚀
