import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/seat_provider.dart';
import '../utils/constants.dart';

class TicketSelectionScreen extends StatelessWidget {
  final int eventId;
  const TicketSelectionScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final checkoutProvider = context.watch<CheckoutProvider>();
    final seatProvider = context.watch<SeatProvider>();
    final event = eventProvider.selectedEvent;

    if (event == null || event.id != eventId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Tickets'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: event.ticketTypes.length,
        itemBuilder: (context, index) {
          final ticket = event.ticketTypes[index];
          final quantity = checkoutProvider.selectedTickets[ticket] ?? 0;
          final isSoldOut = ticket.stock <= 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Rp ${ticket.price.toStringAsFixed(0)}', style: const TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(isSoldOut ? 'Sold Out' : 'Available: ${ticket.stock}', style: TextStyle(color: isSoldOut ? Colors.red : Colors.grey)),
                      ],
                    ),
                  ),
                  if (!isSoldOut) Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppConstants.primaryColor,
                        onPressed: quantity > 0 ? () => checkoutProvider.removeTicket(ticket) : null,
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppConstants.primaryColor,
                        onPressed: quantity < ticket.maxBuy && quantity < ticket.stock 
                          ? () => checkoutProvider.addTicket(ticket) 
                          : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: checkoutProvider.totalQuantity > 0 ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${checkoutProvider.totalQuantity} Tickets', style: const TextStyle(color: Colors.grey)),
                Text('Rp ${checkoutProvider.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                int requiredSeats = 0;
                checkoutProvider.selectedTickets.forEach((ticket, qty) {
                  if (ticket.requiresSeat) {
                    requiredSeats += qty;
                  }
                });
                
                if (requiredSeats > 0 && requiredSeats != seatProvider.selectedSeatIds.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Jumlah tiket yang dipilih ($requiredSeats) tidak sesuai dengan jumlah kursi yang direservasi (${seatProvider.selectedSeatIds.length}).')),
                  );
                  return;
                }
                
                context.push('/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Checkout', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ) : null,
    );
  }
}
