class Organizer {
  final int id;
  final String companyName;
  final String? publicName;
  final String? slug;
  final String? logo;
  final String? coverImage;
  final bool verificationBadge;
  final String status;
  final double ratingAverage;
  final int totalReviews;

  Organizer({
    required this.id,
    required this.companyName,
    this.publicName,
    this.slug,
    this.logo,
    this.coverImage,
    this.verificationBadge = false,
    this.status = 'pending',
    this.ratingAverage = 0.0,
    this.totalReviews = 0,
  });

  factory Organizer.fromJson(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'],
      companyName: json['company_name'],
      publicName: json['public_name'],
      slug: json['slug'],
      logo: json['logo'],
      coverImage: json['cover_image'],
      verificationBadge: json['verification_badge'] == 1 || json['verification_badge'] == true,
      status: json['status'] ?? 'pending',
      ratingAverage: (json['rating_average'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
    );
  }
}
