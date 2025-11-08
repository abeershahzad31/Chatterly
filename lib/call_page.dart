import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallPage extends StatelessWidget {
  final String callID;
  final bool isVideo;

  const CallPage({
    super.key,
    required this.callID,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Get current logged-in Firebase user
    final user = FirebaseAuth.instance.currentUser;

    final String effectiveUserID =
        user?.uid ?? "guest_${DateTime.now().millisecondsSinceEpoch}";

    // ✅ Always ensure userName is NOT empty
    final String effectiveUserName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.isNotEmpty ?? false)
            ? user!.email!
            : (user?.phoneNumber?.isNotEmpty ?? false)
                ? user!.phoneNumber!
                : "Chatterly User";

    debugPrint(
      "📞 Opening CallPage → callID: $callID | userID: $effectiveUserID | userName: $effectiveUserName | isVideo: $isVideo",
    );

    return ZegoUIKitPrebuiltCall(
      appID: 168578403, // 🔑 Replace with your Zego AppID
      appSign:
          "90dc90ec021bbd6c2fce0c996b7f558bf44ce2686929c5d9ed3078ca31b73076", // 🔑 Replace with your Zego AppSign
      userID: effectiveUserID,
      userName: effectiveUserName, // ✅ always safe, not empty
      callID: callID, // 🚨 MUST be identical for caller & callee
      config: isVideo
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}
