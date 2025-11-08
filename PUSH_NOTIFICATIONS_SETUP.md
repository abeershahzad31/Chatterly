# Push Notifications Setup Guide

This guide will help you set up push notifications for both calls and messages in your Chatterly app.

## 🔧 Setup Steps

### 1. Firebase Console Configuration

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project** (or create a new one)
3. **Enable Cloud Messaging**:
   - Go to Project Settings → Cloud Messaging
   - Note down your **Project ID**

### 2. Create Service Account

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your Firebase project**
3. **Navigate to IAM & Admin → Service Accounts**
4. **Create a new service account**:
   - Name: `fcm-service-account`
   - Role: `Firebase Admin SDK Administrator Service Agent`
5. **Create and download the JSON key**
6. **Extract the required information**:
   - `client_email`
   - `private_key`

### 3. Update FCM Configuration

Open `lib/config/fcm_config.dart` and replace the placeholder values:

```dart
class FCMConfig {
  // Replace with your actual Firebase project credentials
  static const String projectId = 'your-actual-project-id';
  static const String clientEmail = 'your-service-account@your-project.iam.gserviceaccount.com';
  static const String privateKey = '''-----BEGIN PRIVATE KEY-----
your-actual-private-key-here
-----END PRIVATE KEY-----''';
}
```

### 4. Android Configuration

1. **Add to `android/app/build.gradle`**:
```gradle
android {
    compileSdkVersion 34
    // ... other config
    
    defaultConfig {
        // ... other config
        minSdkVersion 21
    }
}
```

2. **Add to `android/app/src/main/AndroidManifest.xml`**:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 5. iOS Configuration

1. **Add to `ios/Runner/Info.plist`**:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

2. **Upload APNs certificate to Firebase Console**:
   - Go to Project Settings → Cloud Messaging
   - Upload your APNs certificate or key

## 📱 How It Works

### Call Notifications
- When a user initiates a call (audio or video), a push notification is sent to the recipient
- The notification includes:
  - Caller's name
  - Call type (audio/video)
  - Call ID for joining

### Message Notifications
- When a user sends a message, a push notification is sent to the recipient
- The notification includes:
  - Sender's name
  - Message preview (truncated for long messages)
  - Special formatting for images and voice messages

## 🔧 Features Implemented

### Enhanced ChatProvider Methods:
- `sendCallNotification()` - Sends call notifications
- `sendMessageNotification()` - Sends message notifications
- `getUserFcmToken()` - Retrieves user's FCM token
- `getUserName()` - Gets user's display name

### Smart Notification Content:
- **Text messages**: Shows sender name and message preview
- **Images**: Shows "📷 [Sender] sent a photo"
- **Voice messages**: Shows "🎤 [Sender] sent a voice message"
- **Calls**: Shows "📞/📹 [Caller] is calling you..."

### Automatic Integration:
- Call notifications are sent when calls are initiated from:
  - Call tab
  - Chat screen call buttons
- Message notifications are sent automatically when:
  - Text messages are sent
  - Images are shared
  - Voice messages are sent

## 🚀 Testing

1. **Configure your FCM credentials** in `lib/config/fcm_config.dart`
2. **Run the app** on two different devices (or use an emulator + physical device)
3. **Test call notifications**:
   - Initiate a call from one device
   - Check if the other device receives a notification
4. **Test message notifications**:
   - Send a message from one device
   - Check if the other device receives a notification

## 🔍 Troubleshooting

### Common Issues:

1. **No notifications received**:
   - Check if FCM credentials are correctly configured
   - Verify that FCM tokens are being saved to Firestore
   - Check device notification permissions

2. **Notifications not personalized**:
   - Ensure user data (username) is stored in Firestore
   - Check if `getUserName()` method is working correctly

3. **Call notifications not working**:
   - Verify that call buttons are properly integrated
   - Check if `sendCallNotification()` is being called

### Debug Information:
- Check console logs for FCM response messages
- Verify FCM token storage in Firestore
- Test with Firebase Console's "Send test message" feature

## 📝 Notes

- Notifications are only sent if FCM credentials are properly configured
- The system gracefully handles missing FCM tokens
- All notification methods include error handling
- Notifications work for both foreground and background app states

## 🔐 Security

- Keep your service account credentials secure
- Never commit the actual credentials to version control
- Consider using environment variables for production
- Regularly rotate your service account keys
