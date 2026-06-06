import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/organizer_provider.dart';
import '../utils/constants.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();
    final data = provider.dashboardData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : data == null
                  ? const Center(child: Text('Data tidak tersedia'))
                  : RefreshIndicator(
                      onRefresh: () => context.read<OrganizerProvider>().fetchDashboard(),
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              _buildStatCard('Total Event', data['total_events'].toString(), Icons.event),
                              _buildStatCard('Tiket Terjual', data['total_tickets_sold'].toString(), Icons.confirmation_number),
                              _buildStatCard(
                                'Total Revenue',
                                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(num.tryParse(data['total_revenue']?.toString() ?? '0') ?? 0),
                                Icons.account_balance_wallet,
                              ),
                              _buildStatCard('Check-in', data['checked_in_count'].toString(), Icons.check_circle_outline),
                              _buildStatCard('Event Aktif', data['active_events'].toString(), Icons.event_available),
                              _buildStatCard('Event Mendatang', data['upcoming_events'].toString(), Icons.event_note),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Menu Organizer',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.list_alt, color: AppConstants.primaryColor),
                                  title: const Text('Daftar Event Saya'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => context.push('/organizer/events'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.qr_code_scanner, color: AppConstants.primaryColor),
                                  title: const Text('Scan Tiket (Validasi)'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => context.push('/scanner'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.account_balance_wallet, color: Colors.teal),
                                  title: const Text('Payouts & Settlement'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => context.push('/organizer/payouts/balance'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppConstants.secondaryColor, size: 28),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
