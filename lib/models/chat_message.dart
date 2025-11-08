import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String receiverId;
  final String messageBody;
  final DateTime? timestamp;
  final String? senderProfilePic; // ✅ NEW FIELD

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.messageBody,
    required this.timestamp,
    this.senderProfilePic, // ✅ OPTIONAL
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'messageBody': messageBody,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'senderProfilePic': senderProfilePic,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      messageBody: map['messageBody'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      senderProfilePic: map['senderProfilePic'] ?? '',
    );
  }
}

