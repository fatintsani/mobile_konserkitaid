import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payout_provider.dart';
import '../models/organizer_payout.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class OrganizerPayoutDetailScreen extends StatefulWidget {
  final int payoutId;

  const OrganizerPayoutDetailScreen({super.key, required this.payoutId});

  @override
  State<OrganizerPayoutDetailScreen> createState() => _OrganizerPayoutDetailScreenState();
}

class _OrganizerPayoutDetailScreenState extends State<OrganizerPayoutDetailScreen> {
  OrganizerPayout? _payout;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetail();
    });
  }

  Future<void> _fetchDetail() async {
    final provider = context.read<PayoutProvider>();
    final payout = await provider.fetchPayoutDetail(widget.payoutId);
    if (mounted) {
      setState(() {
        _payout = payout;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Detail'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payout == null
              ? const Center(child: Text('Payout not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusCard(_payout!),
                      const SizedBox(height: 16),
                      _buildInfoCard('Amount Information', [
                        _buildInfoRow('Amount Requested', formatter.format(_payout!.amount)),
                        _buildInfoRow('Platform Fee', formatter.format(_payout!.platformFee)),
                        const Divider(),
                        _buildInfoRow('Net Transfer Amount', formatter.format(_payout!.netAmount), isBold: true, color: Colors.green),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoCard('Bank Account', [
                        _buildInfoRow('Bank Name', _payout!.bankName),
                        _buildInfoRow('Account Holder', _payout!.bankAccountName),
                        _buildInfoRow('Account Number', _payout!.bankAccountNumber),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoCard('Timeline', [
                        _buildInfoRow('Requested At', DateFormat('dd MMM yyyy, HH:mm').format(_payout!.requestedAt)),
                        if (_payout!.approvedAt != null)
                          _buildInfoRow('Approved At', DateFormat('dd MMM yyyy, HH:mm').format(_payout!.approvedAt!)),
                        if (_payout!.paidAt != null)
                          _buildInfoRow('Paid At', DateFormat('dd MMM yyyy, HH:mm').format(_payout!.paidAt!)),
                      ]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard(OrganizerPayout payout) {
    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    if (payout.status == 'paid') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusMessage = 'Your payout has been paid to your bank account.';
    } else if (payout.status == 'approved') {
      statusColor = Colors.blue;
      statusIcon = Icons.thumb_up;
      statusMessage = 'Your payout has been approved and is awaiting transfer.';
    } else if (payout.status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusMessage = 'Your payout request was rejected.';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusMessage = 'Your payout request is being reviewed.';
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(height: 8),
            Text(
              payout.status.toUpperCase(),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(statusMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
            if (payout.adminNote != null && payout.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(payout.adminNote!, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
