import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';
import '../services/local_notification_service.dart';
import '../utils/constants.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final TicketService _ticketService = TicketService();
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await _ticketService.getMyTickets();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });

      // Schedule reminders for active tickets
      for (var ticket in tickets) {
        if (!ticket.isUsed && ticket.ticketType?.event != null) {
          final event = ticket.ticketType!.event!;
          // Untuk simulasi tahap awal, jadwalkan reminder 10 detik dari sekarang saat membuka halaman
          // Di production, ini seharusnya di-schedule (H-1) dari event.date & event.time
          LocalNotificationService.scheduleEventReminder(
            id: ticket.id,
            title: 'Reminder: ${event.title}',
            body: 'Konser kamu akan dimulai besok di ${event.location}!',
            scheduledDate: DateTime.now().add(const Duration(seconds: 10)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _tickets.isEmpty
                  ? const Center(child: Text('You don\'t have any tickets yet.'))
                  : RefreshIndicator(
                      onRefresh: _fetchTickets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _tickets[index];
                          final event = ticket.ticketType?.event;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => context.push('/my-tickets/${ticket.ticketCode}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            event?.title ?? 'Unknown Event',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: ticket.isUsed ? Colors.red : Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            ticket.isUsed ? 'USED' : 'ACTIVE',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Type: ${ticket.ticketType?.name ?? 'Unknown'}', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text('Code: ${ticket.ticketCode}', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                    const SizedBox(height: 8),
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('Tampilkan Tiket', style: TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold)),
                                        Icon(Icons.arrow_forward_ios, size: 14, color: AppConstants.secondaryColor),
                                      ],
                                    )
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
