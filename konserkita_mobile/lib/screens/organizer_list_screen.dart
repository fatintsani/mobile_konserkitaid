import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/public_organizer_provider.dart';
import '../utils/constants.dart';

class OrganizerListScreen extends StatefulWidget {
  const OrganizerListScreen({super.key});

  @override
  State<OrganizerListScreen> createState() => _OrganizerListScreenState();
}

class _OrganizerListScreenState extends State<OrganizerListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PublicOrganizerProvider>().fetchOrganizers(popular: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Organizers'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PublicOrganizerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          if (provider.organizers.isEmpty) {
            return const Center(child: Text('No organizers found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.organizers.length,
            itemBuilder: (context, index) {
              final org = provider.organizers[index];
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
                    child: Row(
                      children: [
                        const Icon(Icons.people, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${org['followers_count'] ?? 0} followers'),
                        const SizedBox(width: 16),
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('${org['rating_average'] ?? '0.0'}'),
                      ],
                    ),
                  ),
                  onTap: () {
                    context.push('/organizers/${org['slug']}');
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
