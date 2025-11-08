import 'package:chatterly/screens/ProfileScreen.dart';
import 'package:chatterly/screens/document_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

class MessageBubble extends StatefulWidget {
  final String messageId;
  final String text;
  final bool isMe;
  final String chatRoomId;
  final Timestamp? timestamp;
  final int? duration;

  // 👇 User info
  final String username;
  final String email;
  final String? profileImageUrl;

  const MessageBubble({
    super.key,
    required this.messageId,
    required this.text,
    required this.isMe,
    required this.chatRoomId,
    this.timestamp,
    this.duration,
    required this.username,
    required this.email,
    this.profileImageUrl, required Color bubbleColor, required Color textColor, required bool isDocument, required bool isLocation, required originalText, required String time,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final _auth = FirebaseAuth.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(widget.text));
      setState(() => _isPlaying = true);
    }
  }

  /// 🔹 Long press menu placeholder
  void _showOptions(BuildContext context, String displayText) async {
    final currentUserId = _auth.currentUser?.uid ?? "";
    // TODO: Add context menu options (copy, delete, forward, etc.)
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? "";

    if (widget.text == "HIDE:$currentUserId") {
      return const SizedBox.shrink();
    }

    final isDeleted = widget.text == "🚫 This message was deleted";
    final displayText = widget.text.replaceAll(" (edited)", "");

    final isVoice = (widget.text.startsWith('http') ||
            widget.text.startsWith('/') ||
            widget.text.startsWith('assets/')) &&
        (widget.text.endsWith('.mp4') ||
            widget.text.endsWith('.m4a') ||
            widget.text.endsWith('.aac') ||
            widget.text.endsWith('.mp3') ||
            widget.text.endsWith('.wav'));

    final isImage = widget.text.startsWith('http') &&
        (widget.text.endsWith('.jpg') ||
            widget.text.endsWith('.jpeg') ||
            widget.text.endsWith('.png') ||
            widget.text.endsWith('.gif'));

    final isDocument = widget.text.startsWith('http') &&
        (widget.text.endsWith('.pdf') ||
            widget.text.endsWith('.doc') ||
            widget.text.endsWith('.docx') ||
            widget.text.endsWith('.ppt') ||
            widget.text.endsWith('.pptx') ||
            widget.text.endsWith('.xls') ||
            widget.text.endsWith('.xlsx'));

    final textColor = widget.isMe ? Colors.white : Colors.black;

    return GestureDetector(
      onLongPress: () => _showOptions(context, displayText),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.isMe) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      username: widget.username,
                      email: widget.email,
                      profileImageUrl: widget.profileImageUrl, userId: '', 
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[800],
                backgroundImage: (widget.profileImageUrl != null &&
                        widget.profileImageUrl!.isNotEmpty)
                    ? NetworkImage(widget.profileImageUrl!)
                    : null,
                child: (widget.profileImageUrl == null ||
                        widget.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // ==== Bubble ====
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDeleted
                        ? Colors.grey[400]
                        : (widget.isMe
                            ? Colors.teal
                            : const Color(0xFFF1F0F5)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: widget.isMe
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: widget.isMe
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                  ),
                  child: isDeleted
                      ? Text(
                          "🚫 This message was deleted",
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : isVoice
                          ? _buildVoiceUI(textColor)
                          : isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.text,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : isDocument
                                  ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DocumentViewerScreen(
                                                    docUrl: widget.text),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.insert_drive_file,
                                              color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Open Document",
                                            style: TextStyle(
                                              color: widget.isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      displayText,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                      ),
                                    ),
                ),
                // ==== Time + Edited ====
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: widget.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (widget.text.contains("(edited)")) ...[
                        const Text(
                          "edited",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _formatTimestamp(widget.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      if (widget.isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all,
                            size: 14, color: Colors.grey),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceUI(Color textColor) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Icon(
              _isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              color: textColor,
              size: 34,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "";
    final date = ts.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? "PM" : "AM";
    final minutes = date.minute.toString().padLeft(2, '0');
    return "$hour:$minutes $period";
  }
}


