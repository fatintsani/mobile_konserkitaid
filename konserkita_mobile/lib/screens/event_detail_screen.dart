import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/review_provider.dart';
import '../providers/recommendation_provider.dart';
import '../utils/constants.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEventDetail(widget.eventId);
      context.read<ReviewProvider>().fetchRatingSummary(widget.eventId);
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<RecommendationProvider>().logInteraction(widget.eventId, 'view');
      }
    });
  }

  void _handleWishlistToggle(BuildContext context, int eventId) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk menambahkan ke wishlist')),
      );
      context.push('/login');
      return;
    }
    
    context.read<WishlistProvider>().toggleWishlist(eventId).then((success) {
      if (!success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengubah wishlist')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final isWishlisted = wishlistProvider.isInWishlist(widget.eventId);
    final event = eventProvider.selectedEvent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Detail'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (event != null)
            IconButton(
              icon: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: isWishlisted ? AppConstants.secondaryColor : Colors.white,
              ),
              onPressed: () => _handleWishlistToggle(context, widget.eventId),
            ),
        ],
      ),
      body: eventProvider.isLoading || event == null
          ? const Center(child: CircularProgressIndicator())
          : eventProvider.error != null
              ? Center(child: Text(eventProvider.error!))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: event.bannerImage != null
                              ? DecorationImage(
                                  image: NetworkImage(AppConstants.getImageUrl(event.bannerImage!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: event.bannerImage == null ? const Icon(Icons.image, size: 80, color: Colors.grey) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppConstants.primaryColor),
                                const SizedBox(width: 8),
                                Text('${event.date} - ${event.time}', style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppConstants.primaryColor),
                                const SizedBox(width: 8),
                                Text(event.location, style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (event.organizer != null)
                              GestureDetector(
                                onTap: () {
                                  if (event.organizer!.slug != null) {
                                    context.push('/organizers/${event.organizer!.slug}');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: event.organizer!.logo != null ? NetworkImage(AppConstants.getImageUrl(event.organizer!.logo!)) : null,
                                        child: event.organizer!.logo == null ? const Icon(Icons.business) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Organized by', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    event.organizer!.publicName ?? event.organizer!.companyName,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (event.organizer!.verificationBadge)
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.verified, color: Colors.blue, size: 16),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            // Rating Section
                            Consumer<ReviewProvider>(
                              builder: (context, reviewProvider, child) {
                                final summary = reviewProvider.ratingSummary;
                                if (summary == null || summary['total_reviews'] == 0) return const SizedBox.shrink();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 24),
                                            const SizedBox(width: 8),
                                            Text('${summary['average_rating'].toStringAsFixed(1)} / 5.0', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Text('(${summary['total_reviews']} reviews)', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () => context.push('/event/${widget.eventId}/reviews'),
                                          child: const Text('See All', style: TextStyle(color: AppConstants.primaryColor)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              },
                            ),
                            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(event.description, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 24),
                            // Review Button
                            if (event.status == 'completed' || DateTime.parse('${event.date} ${event.time}').isBefore(DateTime.now()))
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.rate_review),
                                  label: const Text('Tulis Review'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppConstants.primaryColor,
                                    side: const BorderSide(color: AppConstants.primaryColor),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => context.push('/event/${widget.eventId}/write-review'),
                                ),
                              ),
                            const SizedBox(height: 24),
                            const Text('Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...event.ticketTypes.map((ticket) => Card(
                              child: ListTile(
                                title: Text(ticket.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Stock: ${ticket.stock}'),
                                trailing: Text('Rp ${ticket.price.toStringAsFixed(0)}', style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: event != null ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (event.isNumberedSeating) {
              context.push('/event/${event.id}/seat-map');
            } else {
              context.push('/event/${event.id}/tickets');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(event.isNumberedSeating ? 'Pilih Kursi' : 'Buy Ticket', style: const TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ) : null,
    );
  }
}
