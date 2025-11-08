# How to Get Your Firebase Service Account Client ID

## 🔍 Step-by-Step Guide

### 1. Download Your Service Account JSON
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `chatterly-9b2d2`
3. Go to **Project Settings** (gear icon)
4. Click on **Service Accounts** tab
5. Click **Generate new private key**
6. Download the JSON file

### 2. Extract the Client ID
Open the downloaded JSON file and look for the `client_id` field. It should look something like:

```json
{
  "type": "service_account",
  "project_id": "chatterly-9b2d2",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-fbsvc@chatterly-9b2d2.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",  // ← This is what you need!
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40chatterly-9b2d2.iam.gserviceaccount.com"
}
```

### 3. Update Your FCM Config
Replace the `clientId` in `lib/config/fcm_config.dart`:

```dart
static const String clientId = '123456789012345678901'; // Replace with your actual client_id
```

### 4. Alternative: Use Complete Service Account JSON
If you prefer, you can also use the complete service account JSON directly. Let me know if you'd like me to show you how to do that instead.

## 🚨 Important Notes
- The `client_id` is a long numeric string
- It's different from your project ID
- Keep this information secure and don't commit it to public repositories
- You can regenerate the service account key if needed

## 🔧 Quick Fix
Once you have the `client_id`, just update this line in `lib/config/fcm_config.dart`:

```dart
static const String clientId = 'YOUR_ACTUAL_CLIENT_ID_HERE';
```

Then your push notifications should work properly!
