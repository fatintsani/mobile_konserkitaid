import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_validation_provider.dart';
import '../utils/constants.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketValidationProvider>();
    final isSuccess = provider.error == null;
    final result = provider.scanResult;

    final Color statusColor = isSuccess ? Colors.green : Colors.red;
    final IconData statusIcon = isSuccess ? Icons.check_circle : Icons.error;
    final String statusMessage = isSuccess 
        ? (result?['message'] ?? 'Tiket Valid, Check-in Berhasil') 
        : (provider.error ?? 'Tiket Tidak Valid');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            provider.clearResult();
            context.pop();
          },
        ),
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, size: 120, color: statusColor),
              const SizedBox(height: 24),
              Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (isSuccess && result?['data'] != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Detail Tiket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Ticket Code: ${result?['data']['ticket_code'] ?? '-'}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Status: ${result?['data']['is_used'] == true || result?['data']['is_used'] == 1 ? 'USED' : 'ACTIVE'}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        if (result?['data']['checked_in_at'] != null)
                          Text('Checked-in at: ${result?['data']['checked_in_at']}', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    provider.clearResult();
                    context.pushReplacement('/scanner');
                  },
                  child: const Text('Scan Lagi', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    provider.clearResult();
                    context.go('/');
                  },
                  child: const Text('Kembali ke Home', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
