class EventCategory {
  final int id;
  final String name;
  final String? nameEn;

  EventCategory({
    required this.id,
    required this.name,
    this.nameEn,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'],
      name: json['name'],
      nameEn: json['name_en'],
    );
  }
}
