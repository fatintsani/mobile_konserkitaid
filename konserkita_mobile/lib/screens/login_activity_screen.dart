import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../utils/constants.dart';

class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().fetchLoginActivities(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<SecurityProvider>().fetchLoginActivities();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getEventIcon(String eventType) {
    if (eventType.contains('success')) return Icons.check_circle;
    if (eventType.contains('failed')) return Icons.error;
    if (eventType.contains('logout')) return Icons.logout;
    if (eventType.contains('revoked')) return Icons.block;
    return Icons.info;
  }

  Color _getEventColor(String eventType) {
    if (eventType.contains('success')) return Colors.green;
    if (eventType.contains('failed')) return Colors.red;
    if (eventType.contains('logout')) return Colors.grey;
    if (eventType.contains('revoked')) return Colors.orange;
    return AppConstants.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Activity')),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          if (provider.activitiesError != null && provider.activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.activitiesError}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchLoginActivities(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.isLoadingActivities && provider.activities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchLoginActivities(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: provider.activities.length + (provider.hasMoreActivities ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == provider.activities.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final activity = provider.activities[index];
                return ListTile(
                  leading: Icon(
                    _getEventIcon(activity['event_type']),
                    color: _getEventColor(activity['event_type']),
                    size: 32,
                  ),
                  title: Text(
                    activity['event_type'].toString().replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Platform: ${activity['platform'] ?? 'Unknown'} • IP: ${activity['ip_address'] ?? 'Unknown'}'),
                      const SizedBox(height: 2),
                      Text(activity['created_at'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
