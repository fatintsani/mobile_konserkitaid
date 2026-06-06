import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketCode;
  const TicketDetailScreen({super.key, required this.ticketCode});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchTicketDetail(widget.ticketCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final ticket = ticketProvider.selectedTicket;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Ticket'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: ticketProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ticketProvider.error != null
              ? Center(child: Text(ticketProvider.error!))
              : ticket == null
                  ? const Center(child: Text('Ticket not found'))
                  : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Text(
                                ticket.ticketType?.event?.title ?? 'Unknown Event',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Type: ${ticket.ticketType?.name ?? '-'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              if (ticket.seatCode != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Seat: ${ticket.seatCode}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.secondaryColor),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ticket.isUsed ? Colors.red : Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ticket.isUsed ? 'USED' : 'ACTIVE',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 32),
                              QrImageView(
                                data: ticket.ticketCode,
                                version: QrVersions.auto,
                                size: 200.0,
                                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppConstants.textColor),
                                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppConstants.textColor),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                ticket.ticketCode,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                              const SizedBox(height: 8),
                              const Text('Tunjukkan QR Code ini saat masuk event', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Event Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.calendar_today, color: AppConstants.secondaryColor),
                                title: Text(ticket.ticketType?.event?.date ?? '-'),
                                subtitle: Text(ticket.ticketType?.event?.time ?? '-'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              ListTile(
                                leading: const Icon(Icons.location_on, color: AppConstants.secondaryColor),
                                title: Text(ticket.ticketType?.event?.location ?? '-'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
