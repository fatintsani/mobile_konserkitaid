import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/refund_provider.dart';
import '../utils/constants.dart';

class MyRefundsScreen extends StatefulWidget {
  const MyRefundsScreen({super.key});

  @override
  State<MyRefundsScreen> createState() => _MyRefundsScreenState();
}

class _MyRefundsScreenState extends State<MyRefundsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RefundProvider>().fetchMyRefunds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RefundProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Refunds'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && provider.refunds.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.refunds.isEmpty
              ? Center(child: Text(provider.error!))
              : provider.refunds.isEmpty
                  ? const Center(child: Text('No refunds found.'))
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchMyRefunds(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.refunds.length,
                        itemBuilder: (context, index) {
                          final refund = provider.refunds[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => context.push('/my-refunds/${refund.id}'),
                              title: Text('Transaction #${refund.transactionId}'),
                              subtitle: Text('Rp ${refund.refundAmount.toStringAsFixed(0)}'),
                              trailing: Chip(
                                label: Text(refund.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                backgroundColor: refund.status == 'pending' ? Colors.orange :
                                                 refund.status == 'approved' ? Colors.blue :
                                                 refund.status == 'processed' ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
