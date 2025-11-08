import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String currentUserId;
  const NotificationsScreen({super.key, required this.currentUserId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.4),
        toolbarHeight: 100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () => _showClearAllDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),  
            topRight: Radius.circular(20), 
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: NotificationService.getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading notifications: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group notifications by date
            final today = _filterNotificationsByDate(notifications, DateTime.now());
            final thisWeek = _filterNotificationsByWeek(notifications, DateTime.now());
            final older = _filterOlderNotifications(notifications, DateTime.now());

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (today.isNotEmpty) ...[
                  _buildSectionTitle("Today"),
                  ...today.map((n) => _buildNotificationTile(n)),
                  const SizedBox(height: 20),
                ],
                if (thisWeek.isNotEmpty) ...[
                  _buildSectionTitle("This Week"),
                  ...thisWeek.map((n) => _buildNotificationTile(n)),
                  const SizedBox(height: 20),
                ],
                if (older.isNotEmpty) ...[
                  _buildSectionTitle("Older"),
                  ...older.map((n) => _buildNotificationTile(n)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'system';
    final timestamp = notification['createdAt'] != null 
        ? DateTime.parse(notification['createdAt'])
        : DateTime.now();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isRead ? Colors.white : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(type),
          child: Icon(_getNotificationIcon(type), color: Colors.white),
        ),
        title: Text(
          notification["title"] ?? "Notification",
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification["body"] ?? "",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () => _onNotificationTap(notification),
        onLongPress: () => _showNotificationOptions(notification),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'call':
        return Colors.green;
      case 'message':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'call':
        return Icons.phone;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  List<Map<String, dynamic>> _filterNotificationsByDate(
      List<Map<String, dynamic>> notifications, DateTime date) {
    return notifications.where((notification) {
      if (notification['createdAt'] == null) return false;
      final notificationDate = DateTime.parse(notification['createdAt']);
      return notificationDate.year == date.year &&
          notificationDate.month == date.month &&
          notificationDate.day == date.day;
    }).toList();
  }

  List<Map<String, dynamic>> _filterNotificationsByWeek(
      List<Map<String, dynamic>> notifications, DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return notifications.where((notification) {
      if (notification['createdAt'] == null) return false;
      final notificationDate = DateTime.parse(notification['createdAt']);
      return notificationDate.isAfter(weekStart) &&
          notificationDate.isBefore(weekEnd.add(const Duration(days: 1))) &&
          !(notificationDate.year == date.year &&
              notificationDate.month == date.month &&
              notificationDate.day == date.day);
    }).toList();
  }

  List<Map<String, dynamic>> _filterOlderNotifications(
      List<Map<String, dynamic>> notifications, DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));

    return notifications.where((notification) {
      if (notification['createdAt'] == null) return false;
      final notificationDate = DateTime.parse(notification['createdAt']);
      return notificationDate.isBefore(weekStart);
    }).toList();
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    if (!(notification['isRead'] ?? false)) {
      NotificationService.markAsRead(notification['docId']);
    }

    // Handle navigation based on notification type
    final type = notification['type'];
    final additionalData = notification['additionalData'] ?? {};

    if (type == 'message' && additionalData['chatId'] != null) {
      // Navigate to chat screen
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': additionalData['chatId'],
          'receiverId': notification['senderId'],
          'receiverName': notification['senderName'] ?? 'Chat',
          'receiverPic': '',
        },
      );
    } else if (type == 'call') {
      // Show call details or navigate to call history
      _showCallDetails(notification);
    }
  }

  void _showCallDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? 'Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${notification['senderName'] ?? 'Unknown'}'),
            Text('Time: ${_formatTime(DateTime.parse(notification['createdAt']))}'),
            if (notification['additionalData']?['isVideo'] == true)
              const Text('Type: Video Call')
            else
              const Text('Type: Voice Call'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: Text(notification['isRead'] ? 'Mark as unread' : 'Mark as read'),
              onTap: () {
                Navigator.pop(context);
                if (notification['isRead']) {
                  // TODO: Implement mark as unread
                } else {
                  NotificationService.markAsRead(notification['docId']);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                NotificationService.deleteNotification(notification['docId']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationService.clearAllNotifications();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
