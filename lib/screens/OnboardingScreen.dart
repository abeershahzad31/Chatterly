import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../routes/app_routes.dart';
import 'UsersScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Google Login
  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google login error: $e");
      return null;
    }
  }

  /// Facebook Login
  Future<UserCredential?> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        return await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);
      } else {
        debugPrint("Facebook login failed: ${result.status}");
      }
    } catch (e) {
      debugPrint("Facebook login error: $e");
    }
    return null;
  }

  /// Apple Login
  Future<UserCredential?> _signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    } catch (e) {
      debugPrint("Apple login error: $e");
      return null;
    }
  }

  void _handleSocialLogin(BuildContext context, Future<UserCredential?> login) async {
    final user = await login;
    if (user != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UsersScreen(currentUserId: user.user!.uid)),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Login failed, please try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0E2E),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                /// Logo Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/logo.png", height: 32, width: 32),
                    const SizedBox(width: 6),
                    Text(
                      "Chatbox",
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Poppins",
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                /// Tagline
                Text(
                  "Connect friends",
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: "Poppins",
                    fontSize: 52,
                    height: 1.1,
                  ),
                ),
                Text(
                  "easily & quickly",
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: "Poppins",
                    fontSize: 54,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 16),

                /// Description
                Text(
                  "Our chat app is the perfect way to stay connected with friends and family.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    fontFamily: "Poppins",
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                /// Social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton("assets/facebook.png", () {
                      _handleSocialLogin(context, _signInWithFacebook());
                    }),
                    const SizedBox(width: 24),
                    _socialButton("assets/google.png", () {
                      _handleSocialLogin(context, _signInWithGoogle());
                    }),
                    const SizedBox(width: 24),
                    _socialButton("assets/apple.png", () {
                      _handleSocialLogin(context, _signInWithApple());
                    }),
                  ],
                ),

                const SizedBox(height: 40),

                /// Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "OR",
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 40),

                /// Signup button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: const Text(
                    "Sign up with mail",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Existing account? ",
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.login);
                      },
                      child: Text(
                        "Log in",
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontFamily: "Poppins",
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Social button widget
  Widget _socialButton(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
