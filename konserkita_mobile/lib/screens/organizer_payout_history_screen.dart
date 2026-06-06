import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/payout_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class OrganizerPayoutHistoryScreen extends StatefulWidget {
  const OrganizerPayoutHistoryScreen({super.key});

  @override
  State<OrganizerPayoutHistoryScreen> createState() => _OrganizerPayoutHistoryScreenState();
}

class _OrganizerPayoutHistoryScreenState extends State<OrganizerPayoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayoutProvider>().fetchPayouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayoutProvider>();
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout History'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && provider.payouts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchPayouts(),
              child: provider.payouts.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.8,
                        alignment: Alignment.center,
                        child: const Text('No payouts found.'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.payouts.length,
                      itemBuilder: (context, index) {
                        final payout = provider.payouts[index];
                        final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(payout.requestedAt);
                        
                        Color statusColor;
                        if (payout.status == 'paid') statusColor = Colors.green;
                        else if (payout.status == 'approved') statusColor = Colors.blue;
                        else if (payout.status == 'rejected') statusColor = Colors.red;
                        else statusColor = Colors.orange;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(formatter.format(payout.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${payout.bankName} - ${payout.bankAccountNumber}'),
                                const SizedBox(height: 4),
                                Text(dateFormatted, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                payout.status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            onTap: () => context.push('/organizer/payouts/${payout.id}'),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
