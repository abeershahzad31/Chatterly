import 'package:chatterly/screens/OnboardingScreen.dart';
import 'package:chatterly/screens/UsersScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();

    /// Wait 2 seconds, then check login status
    Future.delayed(const Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('userId');

      if (!mounted) return;

      if (savedUserId != null) {
        // ✅ User already logged in → go to UsersScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UsersScreen(currentUserId: savedUserId),
          ),
        );
      } else {
        // ❌ No login found → go to Onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Logo (from assets)
            Image.asset(
              "assets/logo.png", // 👈 must exist in pubspec.yaml
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}










