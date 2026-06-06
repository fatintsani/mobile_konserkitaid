import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/refund_provider.dart';
import '../utils/constants.dart';

class RefundDetailScreen extends StatelessWidget {
  final int refundId;

  const RefundDetailScreen({super.key, required this.refundId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RefundProvider>();
    final refund = provider.refunds.firstWhere((r) => r.id == refundId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Details'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(refund.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: refund.status == 'pending' ? Colors.orange :
                                       refund.status == 'approved' ? Colors.blue :
                                       refund.status == 'processed' ? Colors.green : Colors.red,
                    ),
                    const Divider(height: 32),
                    const Text('Transaction ID', style: TextStyle(color: Colors.grey)),
                    Text('#${refund.transactionId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Refund Amount', style: TextStyle(color: Colors.grey)),
                    Text('Rp ${refund.refundAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 16),
                    const Text('Reason', style: TextStyle(color: Colors.grey)),
                    Text(refund.reason, style: const TextStyle(fontSize: 16)),
                    if (refund.adminNote != null) ...[
                      const Divider(height: 32),
                      const Text('Admin Note', style: TextStyle(color: Colors.red)),
                      Text(refund.adminNote!, style: const TextStyle(fontSize: 16)),
                    ],
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
