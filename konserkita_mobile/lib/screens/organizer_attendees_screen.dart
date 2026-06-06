import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organizer_provider.dart';
import '../utils/constants.dart';

class OrganizerAttendeesScreen extends StatefulWidget {
  final int eventId;
  const OrganizerAttendeesScreen({super.key, required this.eventId});

  @override
  State<OrganizerAttendeesScreen> createState() => _OrganizerAttendeesScreenState();
}

class _OrganizerAttendeesScreenState extends State<OrganizerAttendeesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().fetchEventAttendees(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendees'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.attendees.isEmpty
                  ? const Center(child: Text('Belum ada pembeli tiket untuk event ini.'))
                  : RefreshIndicator(
                      onRefresh: () => context.read<OrganizerProvider>().fetchEventAttendees(widget.eventId),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.attendees.length,
                        itemBuilder: (context, index) {
                          final attendee = provider.attendees[index];
                          final isUsed = attendee['status'] == 'used';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isUsed ? Colors.green : Colors.grey[300],
                                child: Icon(
                                  isUsed ? Icons.check : Icons.person,
                                  color: isUsed ? Colors.white : Colors.grey[600],
                                ),
                              ),
                              title: Text(attendee['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(attendee['customer_email']),
                                  const SizedBox(height: 4),
                                  Text('${attendee['ticket_type']} • ${attendee['ticket_code']}', style: const TextStyle(fontSize: 12, color: AppConstants.secondaryColor)),
                                  if (isUsed && attendee['checked_in_at'] != null)
                                    Text('Checked in: ${attendee['checked_in_at']}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isUsed ? Colors.green : Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  attendee['status'].toString().toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
