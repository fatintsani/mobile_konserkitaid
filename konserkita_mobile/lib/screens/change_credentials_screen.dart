import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sensitive_action_confirmation_dialog.dart';

class ChangeCredentialsScreen extends StatefulWidget {
  const ChangeCredentialsScreen({Key? key}) : super(key: key);

  @override
  State<ChangeCredentialsScreen> createState() => _ChangeCredentialsScreenState();
}

class _ChangeCredentialsScreenState extends State<ChangeCredentialsScreen> {
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _emailController = TextEditingController();

  final _passwordFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final token = await requestSensitiveActionToken(context, 'Ubah Password');
    if (token == null) return;

    try {
      await context.read<AuthProvider>().changePassword(
        token,
        _passwordController.text,
        _passwordConfirmationController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah.'), backgroundColor: Colors.green),
      );
      _passwordController.clear();
      _passwordConfirmationController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _changeEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final token = await requestSensitiveActionToken(context, 'Ubah Email');
    if (token == null) return;

    try {
      await context.read<AuthProvider>().changeEmail(token, _emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email berhasil diubah.'), backgroundColor: Colors.green),
      );
      _emailController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ubah Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Password harus diisi';
                          if (val.length < 8) return 'Minimal 8 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordConfirmationController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val != _passwordController.text) return 'Password tidak cocok';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : _changePassword,
                        child: const Text('Simpan Password Baru'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Ubah Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Baru', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Email harus diisi';
                          if (!val.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : _changeEmail,
                        child: const Text('Simpan Email Baru'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
