import '../utils/num_parsers.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String? type;
  final int? relatedId;
  final String? url;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    this.title = '',
    this.message = '',
    this.type,
    this.relatedId,
    this.url,
    this.isRead = false,
    this.createdAt = '',
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'],
      relatedId: json['related_id'],
      url: json['url'],
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class NotificationIndex {
  final List<AppNotification> notifications;
  final int unread;

  const NotificationIndex({
    this.notifications = const [],
    this.unread = 0,
  });

  factory NotificationIndex.fromJson(Map<String, dynamic> json) {
    return NotificationIndex(
      notifications: (json['notifications'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      unread: parseInt(json['unread']),
    );
  }
}