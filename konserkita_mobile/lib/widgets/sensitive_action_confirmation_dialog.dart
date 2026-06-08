import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../providers/auth_provider.dart';

class SensitiveActionConfirmationDialog extends StatefulWidget {
  final String actionName;

  const SensitiveActionConfirmationDialog({Key? key, required this.actionName}) : super(key: key);

  @override
  State<SensitiveActionConfirmationDialog> createState() => _SensitiveActionConfirmationDialogState();
}

class _SensitiveActionConfirmationDialogState extends State<SensitiveActionConfirmationDialog> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _authMethod = 'password'; // 'password' or '2fa'

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.twoFactorEnabled) {
      _authMethod = '2fa';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final securityProvider = context.read<SecurityProvider>();
      String token;

      if (_authMethod == 'password') {
        token = await securityProvider.confirmPassword(_inputController.text);
      } else {
        token = await securityProvider.confirm2Fa(_inputController.text);
      }
      
      if (!mounted) return;
      Navigator.pop(context, token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Konfirmasi Aksi: ${widget.actionName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Silakan konfirmasi identitas Anda menggunakan ${_authMethod == 'password' ? 'Password' : 'Kode 2FA'} untuk melanjutkan.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: _authMethod == 'password' ? 'Password' : 'Kode 2FA',
                border: const OutlineInputBorder(),
              ),
              obscureText: _authMethod == 'password',
              keyboardType: _authMethod == '2fa' ? TextInputType.number : TextInputType.text,
              validator: (val) => val == null || val.isEmpty ? 'Field ini wajib diisi' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Konfirmasi'),
        ),
      ],
    );
  }
}

// Helper to easily show the dialog and get the token
Future<String?> requestSensitiveActionToken(BuildContext context, String actionName) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SensitiveActionConfirmationDialog(actionName: actionName),
  );
}
