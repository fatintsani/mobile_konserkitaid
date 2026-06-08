import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../utils/constants.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().fetchSessions();
    });
  }

  void _revokeSession(int id) async {
    try {
      await context.read<SecurityProvider>().revokeSession(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session revoked successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _revokeOtherSessions() async {
    try {
      await context.read<SecurityProvider>().revokeOtherSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Other sessions revoked successfully'), backgroundColor: Colors.green),
        );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Active Sessions')),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingSessions) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.sessionsError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.sessionsError}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchSessions(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchSessions(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.sessions.length > 1) ...[
                  ElevatedButton.icon(
                    onPressed: _revokeOtherSessions,
                    icon: const Icon(Icons.exit_to_app, color: Colors.white),
                    label: const Text('Revoke All Other Sessions', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Your Active Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...provider.sessions.map((session) {
                  final isCurrent = session['is_current_device'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            session['platform']?.toLowerCase().contains('ios') == true || session['platform']?.toLowerCase().contains('android') == true
                                ? Icons.phone_android
                                : Icons.computer,
                            size: 40,
                            color: isCurrent ? AppConstants.primaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(session['device_name'] ?? 'Unknown Device', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('Current', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('IP: ${session['ip_address'] ?? 'Unknown'}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Last Active: ${session['last_active_at'] ?? 'Unknown'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (!isCurrent)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _revokeSession(session['id']),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
