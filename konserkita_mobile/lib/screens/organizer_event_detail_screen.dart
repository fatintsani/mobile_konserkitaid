import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/organizer_provider.dart';
import '../providers/review_provider.dart';
import '../utils/constants.dart';

class OrganizerEventDetailScreen extends StatefulWidget {
  final int eventId;
  const OrganizerEventDetailScreen({super.key, required this.eventId});

  @override
  State<OrganizerEventDetailScreen> createState() => _OrganizerEventDetailScreenState();
}

class _OrganizerEventDetailScreenState extends State<OrganizerEventDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().fetchEventDetail(widget.eventId);
      context.read<ReviewProvider>().fetchRatingSummary(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();
    final event = provider.eventDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Detail'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : event == null
                  ? const Center(child: Text('Data tidak tersedia'))
                  : RefreshIndicator(
                      onRefresh: () => context.read<OrganizerProvider>().fetchEventDetail(widget.eventId),
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['title'],
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          event['status'].toString().toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.calendar_today, color: AppConstants.secondaryColor),
                                    title: Text('${event['date']} ${event['time']}'),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.location_on, color: AppConstants.secondaryColor),
                                    title: Text(event['location']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  color: AppConstants.primaryColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Text('Tiket Terjual', style: TextStyle(color: Colors.white70)),
                                        const SizedBox(height: 8),
                                        Text(
                                          event['total_tickets_sold'].toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  color: AppConstants.secondaryColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Text('Revenue', style: TextStyle(color: Colors.white70)),
                                        const SizedBox(height: 8),
                                        Text(
                                          NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp').format(num.tryParse(event['total_revenue']?.toString() ?? '0') ?? 0),
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Rating Summary
                          Consumer<ReviewProvider>(
                            builder: (context, reviewProvider, child) {
                              final summary = reviewProvider.ratingSummary;
                              if (summary == null || summary['total_reviews'] == 0) return const SizedBox.shrink();
                              return Card(
                                color: Colors.amber.shade50,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade200)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Rating Event', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 20),
                                              const SizedBox(width: 4),
                                              Text('${summary['average_rating'].toStringAsFixed(1)} / 5.0', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Total Reviews', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                          Text('${summary['total_reviews']} users', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Action',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/organizer/events/${widget.eventId}/sales'),
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('Lihat Sales Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/organizer/events/${widget.eventId}/attendees'),
                            icon: const Icon(Icons.people),
                            label: const Text('Daftar Attendees'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/scanner'),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Tiket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/organizer/events/${widget.eventId}/ticket-types'),
                            icon: const Icon(Icons.confirmation_num),
                            label: const Text('Manage Ticket Types'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/organizer/events/${widget.eventId}/edit', extra: provider.events.firstWhere((e) => e.id == widget.eventId)),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Event?'),
                                  content: const Text('Are you sure? This cannot be undone.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                final success = await provider.deleteEvent(widget.eventId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(success ? 'Event deleted' : (provider.error ?? 'Failed to delete'))),
                                  );
                                  if (success) {
                                    context.pop();
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
