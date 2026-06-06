import 'transaction.dart';

class Refund {
  final int id;
  final int transactionId;
  final int userId;
  final String reason;
  final String status;
  final double refundAmount;
  final String? adminNote;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? processedAt;
  final TransactionModel? transaction;

  Refund({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.reason,
    required this.status,
    required this.refundAmount,
    this.adminNote,
    this.requestedAt,
    this.approvedAt,
    this.processedAt,
    this.transaction,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'],
      transactionId: json['transaction_id'],
      userId: json['user_id'],
      reason: json['reason'],
      status: json['status'],
      refundAmount: double.parse(json['refund_amount'].toString()),
      adminNote: json['admin_note'],
      requestedAt: json['requested_at'] != null ? DateTime.parse(json['requested_at']) : null,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      transaction: json['transaction'] != null ? TransactionModel.fromJson(json['transaction']) : null,
    );
  }
}
