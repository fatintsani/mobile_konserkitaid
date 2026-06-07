import 'user.dart';
import 'event.dart';

class Review {
  final int id;
  final int userId;
  final int eventId;
  final int? transactionId;
  final int rating;
  final String? comment;
  final String status;
  final String? adminNote;
  final String createdAt;
  final User? user;
  final Event? event;

  Review({
    required this.id,
    required this.userId,
    required this.eventId,
    this.transactionId,
    required this.rating,
    this.comment,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.user,
    this.event,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      eventId: json['event_id'],
      transactionId: json['transaction_id'],
      rating: json['rating'],
      comment: json['comment'],
      status: json['status'],
      adminNote: json['admin_note'],
      createdAt: json['created_at'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
    );
  }
}
