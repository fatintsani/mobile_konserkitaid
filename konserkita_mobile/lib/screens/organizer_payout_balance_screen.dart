import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/payout_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class OrganizerPayoutBalanceScreen extends StatefulWidget {
  const OrganizerPayoutBalanceScreen({super.key});

  @override
  State<OrganizerPayoutBalanceScreen> createState() => _OrganizerPayoutBalanceScreenState();
}

class _OrganizerPayoutBalanceScreenState extends State<OrganizerPayoutBalanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayoutProvider>().fetchBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayoutProvider>();
    final balance = provider.balance;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout & Settlement'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && balance == null
          ? const Center(child: CircularProgressIndicator())
          : balance == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.error ?? 'Failed to load balance'),
                      ElevatedButton(
                        onPressed: () => provider.fetchBalance(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchBalance(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBalanceCard(balance, formatter),
                        const SizedBox(height: 24),
                        const Text(
                          'Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Request Payout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: balance.availableBalance < 10000
                              ? null
                              : () => context.push('/organizer/payouts/request'),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('Payout History'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => context.push('/organizer/payouts/history'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBalanceCard(dynamic balance, NumberFormat formatter) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(balance.availableBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildBalanceRow('Gross Revenue', formatter.format(balance.grossRevenue)),
            _buildBalanceRow('Platform Fee', formatter.format(balance.platformFee)),
            _buildBalanceRow('Net Revenue', formatter.format(balance.netRevenue), isBold: true),
            const Divider(color: Colors.white24, height: 24),
            _buildBalanceRow('Total Paid Out', formatter.format(balance.totalPaidOut)),
            _buildBalanceRow('Total Locked (Pending)', formatter.format(balance.totalLocked)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(String label, String amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(amount, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
