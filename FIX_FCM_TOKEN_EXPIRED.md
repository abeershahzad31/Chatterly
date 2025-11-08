# 🔧 Fix FCM Token Expired Error

## 🚨 **Problem**
You're getting "FCM token expired" error because your Firebase service account credentials are using demo/placeholder values.

## ✅ **Solution Steps**

### 1. **Get Your Firebase Service Account JSON**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `chatterly-9b2d2`
3. Click **Project Settings** (gear icon)
4. Go to **Service Accounts** tab
5. Click **Generate new private key**
6. Download the JSON file

### 2. **Extract Required Information**
From the downloaded JSON file, copy these values:
- `project_id`
- `client_email` 
- `private_key`
- `client_id`

### 3. **Update FCM Config**
Replace the values in `lib/config/fcm_config.dart`:

```dart
class FCMConfig {
  static const String projectId = 'YOUR_ACTUAL_PROJECT_ID';
  static const String clientEmail = 'YOUR_ACTUAL_CLIENT_EMAIL';
  static const String clientId = 'YOUR_ACTUAL_CLIENT_ID';
  static const String privateKey = '''YOUR_ACTUAL_PRIVATE_KEY''';
}
```

### 4. **Example of Correct Format**
```dart
class FCMConfig {
  static const String projectId = 'my-chat-app-12345';
  static const String clientEmail = 'firebase-adminsdk-abc123@my-chat-app-12345.iam.gserviceaccount.com';
  static const String clientId = '123456789012345678901';
  static const String privateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
...your actual private key content...
-----END PRIVATE KEY-----''';
}
```

## 🔍 **How to Verify It's Fixed**

After updating the credentials:
1. **Restart your app**
2. **Check debug logs** - you should see:
   - `✅ Access token obtained successfully`
   - `📞 Call notification sent. Response: {...}`
3. **Test calls** - notifications should work without "token expired" error

## 🚨 **Security Note**
- **Never commit** real credentials to public repositories
- **Use environment variables** in production
- **Regenerate keys** if accidentally exposed

## 💡 **Quick Test**
Run this in your app to verify credentials:
```dart
final chatProvider = Provider.of<ChatProvider>(context, listen: false);
await chatProvider.sendCallNotification(
  projectId: FCMConfig.projectId,
  clientEmail: FCMConfig.clientEmail,
  privateKey: FCMConfig.privateKey,
  targetUserId: 'test_user_id',
  callerId: 'caller_id',
  isVideoCall: false,
  callId: 'test_call_id',
);
```

If you see `❌ Invalid FCM configuration detected`, your credentials are still using demo values.




