import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/referral_provider.dart';
import '../utils/constants.dart';

class ReferralDashboardScreen extends StatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  State<ReferralDashboardScreen> createState() => _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends State<ReferralDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralProvider>().fetchMyCode();
      context.read<ReferralProvider>().fetchConversions();
      context.read<ReferralProvider>().fetchRewards();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliate & Referrals'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppConstants.secondaryColor,
          tabs: const [
            Tab(text: 'My Code'),
            Tab(text: 'Conversions'),
            Tab(text: 'Rewards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyCodeTab(),
          _ConversionsTab(),
          _RewardsTab(),
        ],
      ),
    );
  }
}

class _MyCodeTab extends StatelessWidget {
  const _MyCodeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReferralProvider>();
    final code = provider.myCode;

    if (provider.isLoading && code == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (code == null) {
      return const Center(child: Text('No referral code active'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchMyCode(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Your Referral Code', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.primaryColor, width: 2),
                      ),
                      child: Text(
                        code['code'],
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppConstants.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code['code']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text('Copy Code', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.secondaryColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Uses',
                    '${code['used_count']} / ${code['usage_limit'] ?? '∞'}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Commission',
                    code['commission_type'] == 'percentage' ? '${code['commission_value']}%' : 'Rp ${code['commission_value']}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ConversionsTab extends StatelessWidget {
  const _ConversionsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReferralProvider>();
    final conversions = provider.conversions;

    return RefreshIndicator(
      onRefresh: () => provider.fetchConversions(),
      child: conversions.isEmpty
          ? const Center(child: Text('No conversions yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversions.length,
              itemBuilder: (context, index) {
                final conv = conversions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    title: Text('Tx: ${conv['transaction_id']}'),
                    subtitle: Text('Status: ${conv['status'].toUpperCase()}'),
                    trailing: Text(
                      'Rp ${double.parse(conv['commission_amount'].toString()).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _RewardsTab extends StatelessWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReferralProvider>();
    final rewards = provider.rewards;

    return RefreshIndicator(
      onRefresh: () => provider.fetchRewards(),
      child: rewards.isEmpty
          ? const Center(child: Text('No rewards yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(reward['status']),
                      child: const Icon(Icons.card_giftcard, color: Colors.white),
                    ),
                    title: Text('Reward Rp ${double.parse(reward['amount'].toString()).toStringAsFixed(0)}'),
                    subtitle: Text('Status: ${reward['status'].toUpperCase()}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
