import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/organizer_provider.dart';
import '../utils/constants.dart';

class OrganizerEventListScreen extends StatefulWidget {
  const OrganizerEventListScreen({super.key});

  @override
  State<OrganizerEventListScreen> createState() => _OrganizerEventListScreenState();
}

class _OrganizerEventListScreenState extends State<OrganizerEventListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().fetchEvents();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published': return Colors.green;
      case 'draft': return Colors.grey;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/organizer/events/create'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.events.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Belum ada event', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => context.read<OrganizerProvider>().fetchEvents(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.events.length,
                        itemBuilder: (context, index) {
                          final event = provider.events[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => context.push('/organizer/events/${event.id}'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(event.status).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              event.status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(event.status),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            event.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(event.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          context.push('/organizer/events/${event.id}/edit', extra: event);
                                        } else if (value == 'delete') {
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
                                            final success = await provider.deleteEvent(event.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(success ? 'Event deleted' : (provider.error ?? 'Failed to delete'))),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text('Edit Event'),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('Delete Event', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
