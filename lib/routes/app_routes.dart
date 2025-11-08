import 'package:chatterly/ai_chatbot.dart'; // ✅ Contains AIChatScreen
import 'package:chatterly/image_upload_screen.dart';
import 'package:chatterly/screens/OnboardingScreen.dart';
import 'package:chatterly/screens/SettingsScreen.dart';
import 'package:chatterly/screens/call_tab.dart'; // ✅ Import CallTab
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your screens
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/personal_details_screen.dart';
import '../call_page.dart';

class AppRoutes {
  // Route names
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String chat = '/chat';
  static const String forgotPassword = '/forgot-password';
  static const String settings = '/settings';
  static const String personalDetails = '/personal-details';
  static const String onboarding = '/onboarding';
  static const String contacts = '/contacts';

  // ✅ AI routes
  static const String aiChatBot = '/ai-chat-bot';

  // ✅ NEW ROUTE FOR IMAGE UPLOAD
  static const String uploadImage = '/upload-image';

  // ✅ NEW ROUTE FOR CALL TAB
  static const String callTab = '/call-tab';

  // ✅ NEW ROUTE FOR CALL PAGE
  static const String call = '/call';

  static Route<dynamic> generateRoute(RouteSettings settingsData) {
    switch (settingsData.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case chat:
        final args = settingsData.arguments;
        if (args is Map<String, dynamic>) {
          final String? receiverId = args['receiverId'];
          final String receiverName = args['receiverName'] ?? 'Unknown';
          final String receiverPic = args['receiverPic'] ?? '';
          final String chatId = args['chatId'] ?? '';

          if (receiverId == null || receiverId.isEmpty || chatId.isEmpty) {
            return _errorRoute(
              "❌ ChatScreen requires a valid chatId and receiverId.",
            );
          }

          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              receiverId: receiverId,
              receiverName: receiverName,
              receiverPic: receiverPic,
              chatRoomId: 'chatRoomId',
              otherUser: {},
            ),
          );
        }
        return _errorRoute(
          "❌ Invalid chat arguments. Expected Map<String, dynamic>.",
        );

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case settings:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
        return MaterialPageRoute(
          builder: (_) => SettingsScreen(currentUserId: currentUserId),
        );

      case personalDetails:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
        return MaterialPageRoute(
          builder: (_) => PersonalDetailsScreen(currentUserId: currentUserId),
        );

      // ✅ Route for Onboarding Screen
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      // ✅ Route for AI ChatBot Screen
      case aiChatBot:
        return MaterialPageRoute(builder: (_) => const AIChatScreen());

      // ✅ Route for Image Upload Screen
      case uploadImage:
        return MaterialPageRoute(builder: (_) => const ImageUploadScreen());

      // ✅ Route for Call Tab
      case callTab:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
        return MaterialPageRoute(
          builder: (_) => CallTab(currentUserId: currentUserId),
        );

      // ✅ Route for Call Page
      case call:
        final args = settingsData.arguments;
        if (args is Map<String, dynamic>) {
          final String? callId = args['callId'];
          final String? callerId = args['callerId'];
          final String callerName = args['callerName'] ?? "Unknown";
          final bool isVideo = args['isVideo'] ?? false;

          if (callId == null || callId.isEmpty || callerId == null || callerId.isEmpty) {
            return _errorRoute(
              "❌ CallPage requires a valid callId and callerId.",
            );
          }

          return MaterialPageRoute(
            builder: (_) => CallPage(
              callID: callId,
              isVideo: isVideo,
            
            ),
          );
        }
        return _errorRoute(
          "❌ Invalid call arguments. Expected Map<String, dynamic>.",
        );

      default:
        return _errorRoute("❌ No route defined for ${settingsData.name}");
    }
  }

  // Error screen in case of bad route navigation
  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: SafeArea(
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



