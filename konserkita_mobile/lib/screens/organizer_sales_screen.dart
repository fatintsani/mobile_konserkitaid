import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/organizer_provider.dart';
import '../utils/constants.dart';

class OrganizerSalesScreen extends StatefulWidget {
  final int eventId;
  const OrganizerSalesScreen({super.key, required this.eventId});

  @override
  State<OrganizerSalesScreen> createState() => _OrganizerSalesScreenState();
}

class _OrganizerSalesScreenState extends State<OrganizerSalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().fetchEventSales(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();
    final sales = provider.eventSales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : sales == null
                  ? const Center(child: Text('Data tidak tersedia'))
                  : RefreshIndicator(
                      onRefresh: () => context.read<OrganizerProvider>().fetchEventSales(widget.eventId),
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          Text(
                            sales['event_title'],
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const Text('Total Pendapatan', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text(
                                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(sales['total_revenue'] ?? 0),
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                                  ),
                                  const Divider(height: 32),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text('Transaksi', style: TextStyle(color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(
                                            sales['total_transactions'].toString(),
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text('Tiket Terjual', style: TextStyle(color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(
                                            sales['total_tickets_sold'].toString(),
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Breakdown per Tipe Tiket',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate((sales['tickets_by_type'] as List).length, (index) {
                            final type = sales['tickets_by_type'][index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(type['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${type['total_sold']} tiket terjual'),
                                trailing: Text(
                                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(type['revenue'] ?? 0),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.secondaryColor),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
    );
  }
}
