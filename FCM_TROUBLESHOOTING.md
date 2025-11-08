# FCM Push Notifications Troubleshooting Guide

## 🚨 Current Issue: "UNREGISTERED" Error

The error you're seeing:
```json
{
  "error": {
    "code": 404,
    "message": "Requested entity was not found.",
    "status": "NOT_FOUND",
    "details": [
      {
        "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
        "errorCode": "UNREGISTERED"
      }
    ]
  }
}
```

This means the FCM token is **invalid or expired**.

## 🔧 Solutions

### 1. **Check if FCM Tokens are Saved**

Add this debug code to your app to check FCM token status:

```dart
// In your chat screen or wherever you test notifications
final chatProvider = Provider.of<ChatProvider>(context, listen: false);
await chatProvider.debugFcmTokenStatus('TARGET_USER_ID');
```

### 2. **Ensure FCM Tokens are Generated**

Make sure both users have FCM tokens saved:

```dart
// Call this when users log in
await chatProvider.saveFcmToken();
```

### 3. **Check Firestore Database**

Go to your Firestore console and check if users have `fcmToken` field:

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Go to Firestore Database
3. Check the `users` collection
4. Look for documents with `fcmToken` field

### 4. **Test FCM Token Generation**

Add this test method to verify FCM is working:

```dart
// Test method to verify FCM token generation
Future<void> testFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    print("🔍 Generated FCM Token: $token");
    
    if (token != null) {
      // Save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        print("✅ FCM token saved to Firestore");
      }
    } else {
      print("❌ Failed to generate FCM token");
    }
  } catch (e) {
    print("❌ FCM token generation error: $e");
  }
}
```

### 5. **Check Android Permissions**

Make sure you have the required permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 6. **Check Firebase Configuration**

Verify your `google-services.json` is properly configured:

1. Download the latest `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. Make sure it matches your project ID: `chatterly-9b2d2`

## 🧪 Testing Steps

### Step 1: Generate FCM Tokens
```dart
// Call this for both users
await chatProvider.saveFcmToken();
```

### Step 2: Check Token Storage
```dart
// Debug the target user's FCM token
await chatProvider.debugFcmTokenStatus('TARGET_USER_ID');
```

### Step 3: Test with Valid Token
Make sure the target user has a valid FCM token before sending notifications.

## 🔍 Common Issues

### Issue 1: No FCM Token Stored
**Solution**: Call `saveFcmToken()` when user logs in

### Issue 2: Expired FCM Token
**Solution**: Regenerate token by calling `saveFcmToken()` again

### Issue 3: Wrong User ID
**Solution**: Verify the `targetUserId` is correct

### Issue 4: Firebase Project Mismatch
**Solution**: Ensure `google-services.json` matches your project

## 🚀 Quick Fix

1. **For both users**, call this when they log in:
   ```dart
   await chatProvider.saveFcmToken();
   ```

2. **Check the console logs** for:
   - "✅ FCM token saved: [token]"
   - "🔍 Target FCM Token: [token]"

3. **If no token is generated**, check:
   - Android permissions
   - Firebase configuration
   - Network connectivity

## 📱 Testing on Real Devices

FCM notifications work best on real devices. Test with:
- Two physical devices
- One device + one emulator (with Google Play Services)
- Make sure both devices are connected to the internet

Let me know what the debug logs show and I'll help you fix the specific issue!
