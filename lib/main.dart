import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🔹 ZegoCloud imports
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';

// Services
import 'services/fcm_service.dart';

// Routes
import 'routes/app_routes.dart';
import 'navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAdnkjUm1aN5VJVrhRceXDe2whGUos55lw",
      appId: "1:450928108429:android:be203e16bcfa8b0ad053c4",
      messagingSenderId: "450928108429",
      projectId: "chatterly-9b2d2",
      storageBucket: "chatterly-9b2d2.firebasestorage.app",
    ),
  );

  // ✅ Register background handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ✅ Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://kxlcpwsfqkpbwnbitphl.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4bGNwd3NmcWtwYnduYml0cGhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0ODU3NDcsImV4cCI6MjA3MzA2MTc0N30.Tg5CY6tXvNGRl1KBoQZb_eMj_pbVfC1h_y_VxDPXmwU',
    );
    print("✅ Supabase initialized successfully");
  } catch (e, stackTrace) {
    print("❌ Failed to initialize Supabase: $e");
    print(stackTrace.toString());
  }

  // ✅ Initialize FCM Service (handles all notification states)
  await FCMService.initialize();

  // ✅ Initialize ZEGOCLOUD Call Invitation Service
  // ⚠️ Use stable IDs (e.g., Firebase UID), not random ones
  ZegoUIKitPrebuiltCallInvitationService().init(
    appID: 168578403, // 👈 your Zego AppID
    appSign: "90dc90ec021bbd6c2fce0c996b7f558bf44ce2686929c5d9ed3078ca31b73076",
    userID: "fixedUserID_here", // 👈 Replace with Firebase UID
    userName: "FixedUserName",  // 👈 Replace with user's actual name
    plugins: [ZegoUIKitSignalingPlugin()],
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for notification actions
    FCMService.setupNotificationActions();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initNotifications(),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chatterly',
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0B1E40),
        ),
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

