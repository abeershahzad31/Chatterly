import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceInputBar extends StatefulWidget {
  final String chatRoomId;

  const VoiceInputBar({
    super.key,
    required this.chatRoomId, required Future<Null> Function(dynamic file) onSend, required void Function() onCancel,
  });

  @override
  State<VoiceInputBar> createState() => _VoiceInputBarState();
}

class _VoiceInputBarState extends State<VoiceInputBar> {
  late final RecorderController _recorderController;

  String? _recordedPath;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorderController.dispose();
    super.dispose();
  }

  /// 🎤 Start recording
  Future<void> _startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

      debugPrint("🎤 Starting recording at path: $path");

      await _recorderController.record(path: path);

      setState(() {
        _isRecording = true;
        _recordedPath = path;
        _recordDuration = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      debugPrint("❌ Error starting recording: $e");
    }
  }

  /// 🛑 Stop recording and send
  Future<void> _stopRecordingAndSend() async {
    try {
      debugPrint("🛑 Stopping recording...");

      await _recorderController.stop();
      _timer?.cancel();

      setState(() => _isRecording = false);

      if (_recordedPath != null && File(_recordedPath!).existsSync()) {
        debugPrint("✅ Recording saved at: $_recordedPath");
        await _uploadAndSend(File(_recordedPath!));
        _recordedPath = null;
      } else {
        debugPrint("⚠️ No recorded file found to upload");
      }
    } catch (e) {
      debugPrint("❌ Error stopping recording: $e");
    }
  }

  /// ⬆️ Upload to Supabase (voices bucket) + Save Firestore
  Future<void> _uploadAndSend(File file) async {
    final supabase = Supabase.instance.client;
   
    const bucket = "voices"; // ✅ FIXED bucket name
    final fileName = "voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

    try {
      debugPrint("⬆️ Uploading voice file to Supabase: $bucket/$fileName");

      await supabase.storage.from(bucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = supabase.storage.from(bucket).getPublicUrl(fileName);
      debugPrint("✅ Voice uploaded, public URL: $url");

      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatRoomId)
          .collection("messages")
          .add({
        "text": url, // stored as a message
        "senderId": FirebaseAuth.instance.currentUser!.uid,
        "timestamp": FieldValue.serverTimestamp(),
        "type": "voice", // 👈 optional, easier to filter later
      });

      debugPrint("📩 Voice message saved in Firestore");
    } catch (e) {
      debugPrint("❌ Upload/send failed: $e");
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (_isRecording) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AudioWaveforms(
                    recorderController: _recorderController,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.blue,
                      extendWaveform: true,
                      showMiddleLine: false,
                    ),
                    size: const Size(double.infinity, 50),
                  ),
                  Text(
                    _formatDuration(_recordDuration),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                "Hold mic to record",
                style: TextStyle(color: Colors.white70),
              ),
            ),

          const SizedBox(width: 8),

          /// 🎙 Mic Button with Hold-to-Record
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecordingAndSend(),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _isRecording ? Colors.red : Colors.blue,
              child: const Icon(Icons.mic, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
