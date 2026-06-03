import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/event_provider.dart';
import '../utils/constants.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final eventProvider = context.watch<EventProvider>();
    final user = context.watch<AuthProvider>().user;
    final event = eventProvider.selectedEvent;

    if (checkoutProvider.selectedTickets.isEmpty || event == null) {
      return const Scaffold(body: Center(child: Text('No tickets selected.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buyer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: AppConstants.primaryColor),
                title: Text(user?.name ?? 'Unknown'),
                subtitle: Text(user?.email ?? ''),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Event Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event, color: AppConstants.secondaryColor),
                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${event.date} - ${event.location}'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Ticket Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: checkoutProvider.selectedTickets.entries.map((entry) {
                    final ticket = entry.key;
                    final qty = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${ticket.name} x $qty'),
                          Text('Rp ${(ticket.price * qty).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppConstants.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Rp ${checkoutProvider.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
        child: ElevatedButton(
          onPressed: checkoutProvider.isLoading ? null : () async {
            bool success = await context.read<CheckoutProvider>().checkout(event.id);
            if (success && context.mounted) {
              context.go('/payment-status');
            } else if (context.mounted && checkoutProvider.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(checkoutProvider.error!), backgroundColor: Colors.red));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.secondaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: checkoutProvider.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Bayar Sekarang', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
