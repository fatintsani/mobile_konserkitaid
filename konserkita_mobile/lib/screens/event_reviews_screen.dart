import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';
import '../utils/constants.dart';

class EventReviewsScreen extends StatefulWidget {
  final int eventId;

  const EventReviewsScreen({super.key, required this.eventId});

  @override
  State<EventReviewsScreen> createState() => _EventReviewsScreenState();
}

class _EventReviewsScreenState extends State<EventReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchEventReviews(widget.eventId);
      context.read<ReviewProvider>().fetchRatingSummary(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (provider.ratingSummary != null && provider.ratingSummary!['total_reviews'] > 0)
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.grey[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              provider.ratingSummary!['average_rating'].toStringAsFixed(1),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < provider.ratingSummary!['average_rating'].floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text('${provider.ratingSummary!['total_reviews']} Reviews', style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                Expanded(
                  child: provider.eventReviews.isEmpty
                      ? const Center(child: Text('Belum ada review untuk event ini.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.eventReviews.length,
                          itemBuilder: (context, index) {
                            final review = provider.eventReviews[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppConstants.primaryColor,
                                              child: Text(
                                                review.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(review.user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ],
                                        ),
                                        Row(
                                          children: List.generate(5, (starIndex) {
                                            return Icon(
                                              starIndex < review.rating ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    if (review.comment != null && review.comment!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(review.comment!, style: const TextStyle(fontSize: 14)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
