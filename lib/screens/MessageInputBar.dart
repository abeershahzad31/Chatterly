import 'package:flutter/material.dart';

class MessageInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onMicTap;
  final VoidCallback onCameraTap;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onMicTap,
    required this.onCameraTap,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            /// 📎 Attachment button → only open menu
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: widget.onAttach,
            ),
            const SizedBox(width: 4),

            /// 📝 Text field
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: "Write your message",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),

            /// 🎤 Mic OR 📨 Send button
            widget.controller.text.isNotEmpty
                ? CircleAvatar(
                    backgroundColor: Colors.teal,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                      onPressed: widget.onSend,
                    ),
                  )
                : Row(
                    children: [
                      /// 📷 Camera button
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.black54, size: 22),
                          onPressed: widget.onCameraTap,
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// 🎤 Mic button
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.mic_none,
                              color: Colors.black54, size: 22),
                          onPressed: widget.onMicTap,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

