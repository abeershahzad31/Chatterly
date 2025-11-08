import 'dart:async';
import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final void Function(String) onSend;
  final VoidCallback onMicStart;
  final VoidCallback onMicStop;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.onMicStart,
    required this.onMicStop,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  void _toggleRecording() {
    if (_isRecording) {
      // stop recording
      widget.onMicStop();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _seconds = 0;
      });
    } else {
      // start recording
      widget.onMicStart();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _seconds++);
      });
      setState(() => _isRecording = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // 🔹 Rounded Input Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    // 😀 Emoji button
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined,
                          color: Colors.grey),
                      onPressed: () {}, // TODO: open emoji picker
                    ),

                    // ✍️ Text Field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),

                    // 📎 Attachment
                    IconButton(
                      icon: const Icon(Icons.attach_file,
                          color: Colors.grey, size: 22),
                      onPressed: () {}, // TODO: open attachment menu
                    ),

                    // 📷 Camera
                    IconButton(
                      icon: const Icon(Icons.camera_alt,
                          color: Colors.grey, size: 22),
                      onPressed: () {}, // TODO: open camera
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // 🔹 Recording Timer
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  "${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

            // 🎤 Mic / Stop Button
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.red : Colors.grey[700],
              ),
              onPressed: _toggleRecording,
            ),

            // 📩 Send Button
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.teal,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

