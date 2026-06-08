import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys_platform_interface/types/register_request.dart';
import '../utils/constants.dart';

class PasskeysScreen extends StatefulWidget {
  const PasskeysScreen({super.key});

  @override
  State<PasskeysScreen> createState() => _PasskeysScreenState();
}

class _PasskeysScreenState extends State<PasskeysScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isRegistering = false;
  List<dynamic> _passkeys = [];

  @override
  void initState() {
    super.initState();
    _fetchPasskeys();
  }

  Future<void> _fetchPasskeys() async {
    try {
      final response = await _apiService.dio.get('/passkeys');
      setState(() {
        _passkeys = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load passkeys: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _registerPasskey() async {
    setState(() => _isRegistering = true);
    final authenticator = PasskeyAuthenticator();
    final authProvider = context.read<AuthProvider>();

    try {
      // 1. Get options from server
      Map<String, dynamic> rawOptions = await authProvider.getPasskeyRegisterOptions();
      
      // 2. Map JSON options to RegisterRequestType
      Map<String, dynamic> options = rawOptions.containsKey('publicKey') 
          ? Map<String, dynamic>.from(rawOptions['publicKey']) 
          : Map<String, dynamic>.from(rawOptions);

      if (options.containsKey('authenticatorSelection')) {
        final authSelection = Map<String, dynamic>.from(options['authenticatorSelection']);
        authSelection['requireResidentKey'] ??= false;
        authSelection['residentKey'] ??= 'discouraged';
        authSelection['userVerification'] ??= 'preferred';
        options['authenticatorSelection'] = authSelection;
      } else {
        options['authenticatorSelection'] = {
          'requireResidentKey': false,
          'residentKey': 'discouraged',
          'userVerification': 'preferred'
        };
      }

      final request = RegisterRequestType.fromJson(options);

      // 3. Register passkey natively
      final attestationResponse = await authenticator.register(request);

      // 4. Send response to backend
      await authProvider.verifyPasskeyRegistration({
        ...attestationResponse.toJson(),
        'name': 'Passkey - ${DateTime.now().toLocal().toString().split('.')[0]}'
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passkey registered successfully!'), backgroundColor: Colors.green),
        );
        _fetchPasskeys();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register passkey: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Future<void> _deletePasskey(int id) async {
    try {
      await _apiService.dio.delete('/passkeys/$id');
      _fetchPasskeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete passkey: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passkeys & WebAuthn')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Manage your passkeys to securely sign in without passwords using fingerprint or face unlock.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isRegistering ? null : _registerPasskey,
                    icon: _isRegistering 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.fingerprint, color: Colors.white),
                    label: const Text('Add New Passkey', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Your Passkeys', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _passkeys.isEmpty
                        ? const Center(child: Text('No passkeys registered yet.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _passkeys.length,
                            itemBuilder: (context, index) {
                              final pk = _passkeys[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.key, color: AppConstants.primaryColor),
                                  title: Text(pk['name']),
                                  subtitle: Text('Created: ${pk['created_at'].substring(0, 10)}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deletePasskey(pk['id']),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
