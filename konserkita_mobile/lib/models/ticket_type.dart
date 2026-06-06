import 'event.dart';

class TicketType {
  final int id;
  final int eventId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int maxBuy;
  final Event? event;

  TicketType({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.maxBuy,
    this.event,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'],
      eventId: json['event_id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      maxBuy: json['max_buy_per_transaction'] ?? 5,
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
    );
  }
}
