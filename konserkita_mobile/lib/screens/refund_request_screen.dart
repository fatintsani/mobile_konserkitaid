import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/refund_provider.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

class RefundRequestScreen extends StatefulWidget {
  final TransactionModel transaction;

  const RefundRequestScreen({super.key, required this.transaction});

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RefundProvider>();
    final refund = await provider.submitRefundRequest(widget.transaction.id, _reasonController.text);

    if (mounted) {
      if (refund != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund request submitted successfully.')));
        context.go('/my-refunds');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to submit.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RefundProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajukan Refund'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction ID: #${widget.transaction.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Estimated Refund: Rp ${widget.transaction.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              const Text('Alasan Refund', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan alasan pengajuan refund Anda secara detail...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Alasan harus diisi' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: provider.isLoading ? null : _submit,
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Kirim Pengajuan Refund', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
