import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Store notification in Firebase when triggered
  static Future<void> storeNotification({
    required String type, // 'call', 'message', 'system'
    required String title,
    required String body,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No logged in user, cannot store notification');
        return;
      }

      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': currentUser.uid,
        'type': type,
        'title': title,
        'body': body,
        'senderId': senderId,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'additionalData': additionalData ?? {},
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('userNotifications')
          .add(notificationData);

      debugPrint('✅ Notification stored in Firebase: $type - $title');
    } catch (e) {
      debugPrint('❌ Failed to store notification: $e');
    }
  }

  /// Get notifications stream for current user
  static Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .doc(currentUser.uid)
        .collection('userNotifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'docId': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Mark notification as read
  static Future<void> markAsRead(String docId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('userNotifications')
          .doc(docId)
          .update({'isRead': true});

      debugPrint('✅ Notification marked as read: $docId');
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
    }
  }

  /// Get unread notification count
  static Stream<int> getUnreadCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .doc(currentUser.uid)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete notification
  static Future<void> deleteNotification(String docId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('userNotifications')
          .doc(docId)
          .delete();

      debugPrint('✅ Notification deleted: $docId');
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('userNotifications')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All notifications cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }
}


