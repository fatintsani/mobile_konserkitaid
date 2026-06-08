import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../utils/constants.dart';

class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().fetchAlerts(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<SecurityProvider>().fetchAlerts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getAlertIcon(String type) {
    if (type == 'new_device_login') return Icons.devices;
    if (type == 'unusual_ip') return Icons.public;
    if (type == 'account_locked') return Icons.lock;
    if (type == 'password_changed') return Icons.password;
    if (type == 'two_factor_disabled') return Icons.security_update_warning;
    if (type == 'passkey_deleted') return Icons.key_off;
    return Icons.warning;
  }

  Color _getSeverityColor(String severity) {
    if (severity == 'critical') return Colors.red.shade900;
    if (severity == 'high') return Colors.red;
    if (severity == 'medium') return Colors.orange;
    if (severity == 'low') return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<SecurityProvider>().markAllAlertsAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All alerts marked as read')),
              );
            },
          ),
        ],
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          if (provider.alertsError != null && provider.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.alertsError}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAlerts(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.isLoadingAlerts && provider.alerts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.alerts.isEmpty) {
            return const Center(
              child: Text(
                'No security alerts found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAlerts(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: provider.alerts.length + (provider.hasMoreAlerts ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == provider.alerts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final alert = provider.alerts[index];
                final bool isRead = alert['is_read'] == true;

                return Container(
                  color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSeverityColor(alert['severity']).withOpacity(0.2),
                      child: Icon(
                        _getAlertIcon(alert['type']),
                        color: _getSeverityColor(alert['severity']),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alert['title'] ?? 'Alert',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(alert['message'] ?? '', style: TextStyle(color: isRead ? Colors.grey.shade700 : Colors.black87)),
                        const SizedBox(height: 8),
                        Text(alert['created_at'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      if (!isRead) {
                        provider.markAlertAsRead(alert['id']);
                      }
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(_getAlertIcon(alert['type']), color: _getSeverityColor(alert['severity'])),
                              const SizedBox(width: 8),
                              Expanded(child: Text(alert['title'] ?? 'Alert')),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alert['message'] ?? ''),
                              const SizedBox(height: 16),
                              Text('Severity: ${alert['severity'].toString().toUpperCase()}'),
                              Text('IP Address: ${alert['ip_address'] ?? 'Unknown'}'),
                              Text('Device: ${alert['user_agent'] ?? 'Unknown'}'),
                              Text('Time: ${alert['created_at']}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
