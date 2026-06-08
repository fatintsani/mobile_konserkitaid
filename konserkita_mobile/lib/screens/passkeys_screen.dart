import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys_platform_interface/types/register_request.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/constants.dart';
import '../widgets/sensitive_action_confirmation_dialog.dart';

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

  // 2FA States
  bool _is2faEnabled = false;
  Map<String, dynamic>? _setupData;
  List<String> _recoveryCodes = [];
  final _confirmCodeController = TextEditingController();
  bool _is2faLoading = false;

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
    
    // Check 2FA status from profile
    if (mounted) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        setState(() {
          _is2faEnabled = user.twoFactorEnabled ?? false;
        });
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
    final token = await requestSensitiveActionToken(context, 'Hapus Passkey');
    if (token == null) return;

    try {
      await _apiService.dio.delete('/passkeys/$id', data: {'confirmation_token': token});
      _fetchPasskeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete passkey: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setup2FA() async {
    setState(() => _is2faLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final data = await authProvider.setup2FA();
      setState(() {
        _setupData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _is2faLoading = false);
    }
  }

  Future<void> _confirm2FA() async {
    setState(() => _is2faLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final codes = await authProvider.confirm2FA(_confirmCodeController.text);
      
      setState(() {
        _is2faEnabled = true;
        _recoveryCodes = codes;
        _setupData = null;
      });
      
      await authProvider.checkAuthStatus(); // refresh user data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA enabled successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _is2faLoading = false);
    }
  }

  Future<void> _disable2FA() async {
    final token = await requestSensitiveActionToken(context, 'Nonaktifkan 2FA');
    if (token == null) return;

    setState(() => _is2faLoading = true);
    try {
      // Modifying AuthProvider's disable2FA to pass the token may be required,
      // but for simplicity we can just call it here or pass token to the provider.
      // Since AuthProvider.disable2FA doesn't accept a token currently, let's update it or just use API directly.
      await _apiService.dio.post('/2fa/disable', data: {'confirmation_token': token});
      
      setState(() {
        _is2faEnabled = false;
        _recoveryCodes = [];
      });
      
      await context.read<AuthProvider>().checkAuthStatus(); // refresh user data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA disabled successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _is2faLoading = false);
    }
  }

  Future<void> _regenerateRecoveryCodes() async {
    setState(() => _is2faLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final codes = await authProvider.regenerateRecoveryCodes();
      
      setState(() {
        _recoveryCodes = codes;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery codes regenerated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _is2faLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passkeys & WebAuthn')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  _passkeys.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No passkeys registered yet.', style: TextStyle(color: Colors.grey))))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                  const Divider(height: 32),
                  const Text('Two-Factor Authentication (TOTP)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Protect your account with 2FA using Google Authenticator or Authy.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  if (_is2faEnabled) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('✓ 2FA is Enabled', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: _is2faLoading ? null : _disable2FA,
                          child: const Text('Disable 2FA', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    if (_recoveryCodes.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          border: Border.all(color: Colors.yellow.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recovery Codes', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Save these codes in a secure location. They will not be shown again.', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _recoveryCodes.map((c) => Chip(label: Text(c, style: const TextStyle(fontFamily: 'monospace')))).toList(),
                            ),
                          ],
                        ),
                      )
                    ] else ...[
                      TextButton(
                        onPressed: _is2faLoading ? null : _regenerateRecoveryCodes,
                        child: const Text('Regenerate Recovery Codes'),
                      ),
                    ]
                  ] else if (_setupData == null) ...[
                    ElevatedButton(
                      onPressed: _is2faLoading ? null : _setup2FA,
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Enable 2FA', style: TextStyle(color: Colors.white)),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('1. Scan QR or enter secret manually'),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.white,
                            child: QrImageView(
                              data: 'otpauth://totp/KonserKita:${context.read<AuthProvider>().user?.email ?? ''}?secret=${_setupData!['secret']}&issuer=KonserKita',
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SelectableText(_setupData!['secret'], style: const TextStyle(fontFamily: 'monospace', fontSize: 18, letterSpacing: 2)),
                          const SizedBox(height: 16),
                          const Text('2. Enter 6-digit code'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmCodeController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '000000'),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _is2faLoading ? null : _confirm2FA,
                            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, minimumSize: const Size(double.infinity, 48)),
                            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
    );
  }
}
