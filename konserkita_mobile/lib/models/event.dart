import 'ticket_type.dart';
import 'event_category.dart';

class Event {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String date;
  final String time;
  final String location;
  final String? bannerImage;
  final String status;
  final List<TicketType> ticketTypes;
  final EventCategory? category;

  Event({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    this.bannerImage,
    required this.status,
    required this.ticketTypes,
    this.category,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    var list = json['ticket_types'] as List? ?? [];
    List<TicketType> ticketTypesList = list.map((i) => TicketType.fromJson(i)).toList();

    return Event(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      description: json['description'],
      date: json['date'],
      time: json['time'],
      location: json['location'],
      bannerImage: json['banner_image'],
      status: json['status'],
      ticketTypes: ticketTypesList,
      category: json['category'] != null ? EventCategory.fromJson(json['category']) : null,
    );
  }
}
