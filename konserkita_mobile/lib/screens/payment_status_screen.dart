import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/checkout_provider.dart';
import '../utils/constants.dart';

class PaymentStatusScreen extends StatelessWidget {
  const PaymentStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final transaction = checkoutProvider.transactionResult;

    if (transaction == null) {
      return const Scaffold(body: Center(child: Text('No transaction found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevent back to checkout
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 80, color: AppConstants.primaryColor),
              const SizedBox(height: 24),
              const Text('Transaction Pending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Please complete your payment', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Invoice:', style: TextStyle(color: Colors.grey)),
                          Text('#${transaction['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(color: Colors.grey)),
                          Text('Rp ${transaction['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              if (checkoutProvider.isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    bool success = await context.read<CheckoutProvider>().simulatePaymentSuccess();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment simulated successfully!'), backgroundColor: Colors.green));
                      context.read<CheckoutProvider>().clearSelection();
                      context.go('/my-tickets');
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to simulate payment'), backgroundColor: Colors.red));
                    }
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Simulate Payment Success', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  context.read<CheckoutProvider>().clearSelection();
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: AppConstants.primaryColor),
                ),
                child: const Text('Back to Home', style: TextStyle(color: AppConstants.primaryColor)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
