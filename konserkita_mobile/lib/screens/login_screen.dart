import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/social_auth_provider.dart';
import '../utils/constants.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys_platform_interface/types/authenticate_request.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<AuthProvider>().login(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) context.go('/');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _loginWithGoogle() async {
    final success = await context.read<SocialAuthProvider>().loginWithGoogle();
    if (success && mounted) {
      await context.read<AuthProvider>().checkAuthStatus();
      if (mounted) context.go('/');
    } else if (mounted) {
      final error = context.read<SocialAuthProvider>().error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _loginWithMicrosoft() async {
    final success = await context.read<SocialAuthProvider>().loginWithMicrosoft();
    if (success && mounted) {
      await context.read<AuthProvider>().checkAuthStatus();
      if (mounted) context.go('/');
    } else if (mounted) {
      final error = context.read<SocialAuthProvider>().error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _loginWithPasskey() async {
    final authenticator = PasskeyAuthenticator();
    final authProvider = context.read<AuthProvider>();

    try {
      final email = _emailController.text;
      Map<String, dynamic> rawOptions = await authProvider.getPasskeyLoginOptions(email);

      Map<String, dynamic> options = rawOptions.containsKey('publicKey')
          ? Map<String, dynamic>.from(rawOptions['publicKey'])
          : Map<String, dynamic>.from(rawOptions);

      final request = AuthenticateRequestType.fromJson(options);
      final authResponse = await authenticator.authenticate(request);

      final success = await authProvider.verifyPasskeyLogin(authResponse.toJson(), email);
      if (success && mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.music_note, size: 80, color: AppConstants.primaryColor),
                const SizedBox(height: 24),
                const Text(
                  'KonserKita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) => value!.isEmpty ? 'Email required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Password required' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: context.watch<SocialAuthProvider>().isLoading ? null : _loginWithGoogle,
                  icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', height: 24),
                  label: const Text('Continue with Google', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: context.watch<SocialAuthProvider>().isLoading ? null : _loginWithMicrosoft,
                  icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/120px-Microsoft_logo.svg.png', height: 24),
                  label: const Text('Continue with Microsoft', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: context.watch<AuthProvider>().isLoading ? null : _loginWithPasskey,
                  icon: const Icon(Icons.fingerprint, size: 24, color: AppConstants.primaryColor),
                  label: const Text('Sign in with Passkey', style: TextStyle(fontSize: 16, color: AppConstants.primaryColor)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Don\'t have an account? Register here', style: TextStyle(color: AppConstants.primaryColor)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
