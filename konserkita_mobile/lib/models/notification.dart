class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'],
    );
  }
}
