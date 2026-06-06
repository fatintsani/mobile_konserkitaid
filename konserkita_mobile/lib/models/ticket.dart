import 'ticket_type.dart';

class Ticket {
  final int id;
  final int transactionId;
  final int ticketTypeId;
  final int userId;
  final String ticketCode;
  final bool isUsed;
  final String? usedAt;
  final String? seatCode;
  final TicketType? ticketType;

  Ticket({
    required this.id,
    required this.transactionId,
    required this.ticketTypeId,
    required this.userId,
    required this.ticketCode,
    required this.isUsed,
    this.usedAt,
    this.seatCode,
    this.ticketType,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      transactionId: json['transaction_id'],
      ticketTypeId: json['ticket_type_id'],
      userId: json['user_id'],
      ticketCode: json['ticket_code'],
      isUsed: json['is_used'] == 1 || json['is_used'] == true,
      usedAt: json['used_at'],
      seatCode: json['seat'] != null ? json['seat']['seat_code'] : null,
      ticketType: json['ticket_type'] != null ? TicketType.fromJson(json['ticket_type']) : null,
    );
  }
}
