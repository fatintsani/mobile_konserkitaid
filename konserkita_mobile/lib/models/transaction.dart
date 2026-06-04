import 'event.dart';
import 'ticket.dart';

class Transaction {
  final int id;
  final String invoiceNumber;
  final int userId;
  final int eventId;
  final double subtotal;
  final double discountAmount;
  final double adminFee;
  final double totalAmount;
  final String paymentStatus;
  final String orderStatus;
  final String? snapToken;
  final String? paymentUrl;
  final String createdAt;
  final Event? event;
  final List<Ticket>? tickets;
  final Map<String, dynamic>? promoCode;

  Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.userId,
    required this.eventId,
    required this.subtotal,
    required this.discountAmount,
    required this.adminFee,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    this.snapToken,
    this.paymentUrl,
    required this.createdAt,
    this.event,
    this.tickets,
    this.promoCode,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      userId: json['user_id'] ?? 0,
      eventId: json['event_id'] ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
      adminFee: double.tryParse(json['admin_fee']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      paymentStatus: json['payment_status'] ?? 'pending',
      orderStatus: json['order_status'] ?? 'pending',
      snapToken: json['snap_token'],
      paymentUrl: json['payment_url'],
      createdAt: json['created_at'] ?? '',
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      tickets: json['tickets'] != null
          ? (json['tickets'] as List).map((i) => Ticket.fromJson(i)).toList()
          : null,
      promoCode: json['promo_code'],
    );
  }
}
