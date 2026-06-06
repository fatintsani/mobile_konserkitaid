import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/payout_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class OrganizerPayoutRequestScreen extends StatefulWidget {
  const OrganizerPayoutRequestScreen({super.key});

  @override
  State<OrganizerPayoutRequestScreen> createState() => _OrganizerPayoutRequestScreenState();
}

class _OrganizerPayoutRequestScreenState extends State<OrganizerPayoutRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PayoutProvider>();
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0;

    final data = {
      'amount': amount,
      'bank_name': _bankNameController.text,
      'bank_account_name': _accountNameController.text,
      'bank_account_number': _accountNumberController.text,
    };

    final result = await provider.requestPayout(data);
    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested successfully')));
        context.pop(); // Go back to balance screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Request failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayoutProvider>();
    final balance = provider.balance?.availableBalance ?? 0;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Payout'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(formatter.format(balance), style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Withdrawal Amount',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  final amountText = val.replaceAll(RegExp(r'[^0-9]'), '');
                  final amount = double.tryParse(amountText) ?? 0;
                  if (amount < 10000) return 'Minimum withdrawal is Rp 10.000';
                  if (amount > balance) return 'Exceeds available balance';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name (e.g., BCA, Mandiri)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: provider.isLoading ? null : _submitRequest,
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
