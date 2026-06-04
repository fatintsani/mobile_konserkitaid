import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/checkout_provider.dart';
import '../utils/constants.dart';

class PaymentStatusScreen extends StatefulWidget {
  final int? transactionId;
  const PaymentStatusScreen({super.key, this.transactionId});

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final tId = widget.transactionId ?? checkoutProvider.transactionResult?['id'];
    if (tId != null) {
      final status = await checkoutProvider.checkPaymentStatus(tId);
      setState(() {
        _status = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final transaction = checkoutProvider.transactionResult;
    final tId = widget.transactionId ?? transaction?['id'];

    if (tId == null) {
      return const Scaffold(body: Center(child: Text('No transaction found.')));
    }

    IconData statusIcon = Icons.pending_actions;
    Color statusColor = Colors.orange;
    String statusTitle = 'Transaction Pending';
    String statusMessage = 'Please complete your payment.';

    if (_status == 'paid' || _status == 'success') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      statusTitle = 'Payment Successful';
      statusMessage = 'Your tickets have been issued.';
    } else if (_status == 'expired' || _status == 'failed') {
      statusIcon = Icons.error;
      statusColor = Colors.red;
      statusTitle = 'Payment Failed';
      statusMessage = 'Your payment has expired or failed.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, size: 80, color: statusColor),
              const SizedBox(height: 24),
              Text(statusTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(statusMessage, style: TextStyle(color: Colors.grey[600], fontSize: 16), textAlign: TextAlign.center,),
              const SizedBox(height: 32),
              
              if (transaction != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Invoice:', style: TextStyle(color: Colors.grey)),
                            Text('#$tId', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                const CircularProgressIndicator(color: AppConstants.primaryColor)
              else if (_status == 'paid' || _status == 'success')
                ElevatedButton(
                  onPressed: () {
                    context.read<CheckoutProvider>().clearSelection();
                    context.go('/my-tickets');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('View My Tickets', style: TextStyle(color: Colors.white)),
                )
              else if (_status == 'pending')
                ElevatedButton(
                  onPressed: _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Check Status Again', style: TextStyle(color: Colors.white)),
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
