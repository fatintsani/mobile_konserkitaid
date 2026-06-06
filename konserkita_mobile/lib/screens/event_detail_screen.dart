import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
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
                            const SizedBox(height: 24),
                            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(event.description, style: const TextStyle(fontSize: 16)),
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
            context.push('/event/${event.id}/tickets');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Buy Ticket', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ) : null,
    );
  }
}
