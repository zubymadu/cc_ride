class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime sentAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'].toString(),
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        data: json['data'] as Map<String, dynamic>?,
        isRead: json['is_read'] as bool? ?? false,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
}
