import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class TransactionDetailScreen extends StatelessWidget {
  final int transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TransactionProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: FutureBuilder<Transaction?>(
        future: provider.fetchTransactionDetail(transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Transaction not found'));
          }

          final transaction = snapshot.data!;

          Color statusColor = Colors.grey;
          if (transaction.paymentStatus == 'success' || transaction.paymentStatus == 'settlement') {
            statusColor = Colors.green;
          } else if (transaction.paymentStatus == 'pending') {
            statusColor = Colors.orange;
          } else if (transaction.paymentStatus == 'expired' || transaction.paymentStatus == 'failed') {
            statusColor = Colors.red;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detail Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailRow('Invoice', transaction.invoiceNumber),
                        _buildDetailRow('Tanggal', transaction.createdAt.substring(0, 10)),
                        _buildDetailRow('Status Pembayaran', transaction.paymentStatus.toUpperCase(), color: statusColor),
                        _buildDetailRow('Status Order', transaction.orderStatus.toUpperCase()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (transaction.event?.id != null) {
                        context.push('/event/${transaction.event!.id}');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(transaction.event?.title ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(transaction.event?.location ?? '-', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (transaction.tickets != null && transaction.tickets!.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daftar Tiket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          ...transaction.tickets!.map((ticket) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ticket.ticketType?.name ?? 'Ticket', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(ticket.ticketCode, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ticket.isUsed ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ticket.isUsed ? 'USED' : 'ACTIVE',
                                      style: TextStyle(color: ticket.isUsed ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rincian Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailRow('Subtotal', currencyFormat.format(transaction.subtotal)),
                        if (transaction.promoCode != null)
                          _buildDetailRow(
                            'Diskon (${transaction.promoCode!['code']})', 
                            '-${currencyFormat.format(transaction.discountAmount)}', 
                            color: Colors.green
                          ),
                        _buildDetailRow('Biaya Admin', currencyFormat.format(transaction.adminFee)),
                        const Divider(),
                        _buildDetailRow('Total Pembayaran', currencyFormat.format(transaction.totalAmount), isBold: true, color: AppConstants.primaryColor),
                      ],
                    ),
                  ),
                ),
                
                if (transaction.paymentStatus == 'pending' && transaction.paymentUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/payment-webview', extra: {
                          'paymentUrl': transaction.paymentUrl,
                          'transactionId': transaction.id,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Lanjutkan Pembayaran',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                
                if (transaction.paymentStatus == 'success')
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/refund-request', extra: transaction);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Ajukan Refund',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
