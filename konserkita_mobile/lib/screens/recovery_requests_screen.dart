import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';

class RecoveryRequestsScreen extends StatefulWidget {
  const RecoveryRequestsScreen({Key? key}) : super(key: key);

  @override
  State<RecoveryRequestsScreen> createState() => _RecoveryRequestsScreenState();
}

class _RecoveryRequestsScreenState extends State<RecoveryRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().fetchRecoveryRequests();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pemulihan Akun')),
      body: Consumer<SecurityProvider>(
        builder: (context, securityProvider, child) {
          if (securityProvider.isLoadingRecoveryRequests) {
            return const Center(child: CircularProgressIndicator());
          }

          if (securityProvider.recoveryRequestsError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    securityProvider.recoveryRequestsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => securityProvider.fetchRecoveryRequests(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final requests = securityProvider.recoveryRequests;

          if (requests.isEmpty) {
            return const Center(child: Text('Tidak ada permintaan pemulihan.'));
          }

          return RefreshIndicator(
            onRefresh: () => securityProvider.fetchRecoveryRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              request['type'].toString().replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(request['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                request['status'].toString().toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(request['status']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Tanggal: ${_formatDate(request['created_at'])}'),
                        if (request['admin_note'] != null) ...[
                          const SizedBox(height: 8),
                          const Text('Catatan Admin:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(request['admin_note']),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
