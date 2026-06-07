import 'ticket_type.dart';
import 'event_category.dart';

class Event {
  final int id;
  final String title;
  final String? titleEn;
  final String slug;
  final String description;
  final String? descriptionEn;
  final String date;
  final String time;
  final String location;
  final String? bannerImage;
  final String status;
  final bool isNumberedSeating;
  final List<TicketType> ticketTypes;
  final EventCategory? category;

  Event({
    required this.id,
    required this.title,
    this.titleEn,
    required this.slug,
    required this.description,
    this.descriptionEn,
    required this.date,
    required this.time,
    required this.location,
    this.bannerImage,
    required this.status,
    this.isNumberedSeating = false,
    required this.ticketTypes,
    this.category,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    var list = json['ticket_types'] as List? ?? [];
    List<TicketType> ticketTypesList = list.map((i) => TicketType.fromJson(i)).toList();

    return Event(
      id: json['id'],
      title: json['title'],
      titleEn: json['title_en'],
      slug: json['slug'],
      description: json['description'],
      descriptionEn: json['description_en'],
      date: json['date'],
      time: json['time'],
      location: json['location'],
      bannerImage: json['banner_image'],
      status: json['status'],
      isNumberedSeating: json['is_numbered_seating'] == 1 || json['is_numbered_seating'] == true,
      ticketTypes: ticketTypesList,
      category: json['category'] != null ? EventCategory.fromJson(json['category']) : null,
    );
  }
}
