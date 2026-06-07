import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/public_organizer_provider.dart';
import '../utils/constants.dart';

class FollowedOrganizersScreen extends StatefulWidget {
  const FollowedOrganizersScreen({super.key});

  @override
  State<FollowedOrganizersScreen> createState() => _FollowedOrganizersScreenState();
}

class _FollowedOrganizersScreenState extends State<FollowedOrganizersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PublicOrganizerProvider>().fetchFollowedOrganizers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followed Organizers'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PublicOrganizerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.followedOrganizers.isEmpty) {
            return const Center(child: Text('You have not followed any organizers.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.followedOrganizers.length,
            itemBuilder: (context, index) {
              final org = provider.followedOrganizers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(org['logo'] ?? ''),
                    onBackgroundImageError: (_, __) => const Icon(Icons.business),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          org['public_name'] ?? org['company_name'] ?? 'Organizer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (org['verification_badge'] == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, color: Colors.blue, size: 16),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${org['followers_count'] ?? 0} followers'),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Unfollow Organizer'),
                          content: const Text('Are you sure you want to unfollow this organizer?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unfollow')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await provider.unfollowOrganizer(org['id']);
                        provider.fetchFollowedOrganizers();
                      }
                    },
                    child: const Text('Unfollow', style: TextStyle(color: Colors.red)),
                  ),
                  onTap: () {
                    if (org['slug'] != null) {
                      context.push('/organizers/${org['slug']}');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
