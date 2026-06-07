import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/public_organizer_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/event_card.dart';

class OrganizerPublicProfileScreen extends StatefulWidget {
  final String slug;

  const OrganizerPublicProfileScreen({super.key, required this.slug});

  @override
  State<OrganizerPublicProfileScreen> createState() => _OrganizerPublicProfileScreenState();
}

class _OrganizerPublicProfileScreenState extends State<OrganizerPublicProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final provider = context.read<PublicOrganizerProvider>();
      provider.fetchOrganizerProfile(widget.slug);
      provider.fetchOrganizerEvents(widget.slug);
      provider.fetchOrganizerReviews(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PublicOrganizerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentOrganizer == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.currentOrganizer == null) {
            return Center(child: Text(provider.error!));
          }

          final org = provider.currentOrganizer;
          if (org == null) {
            return const Center(child: Text('Organizer not found'));
          }

          final authProvider = context.watch<AuthProvider>();
          final isLoggedIn = authProvider.isAuthenticated;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    org['cover_image'] ?? org['logo'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(org['logo'] ?? ''),
                            onBackgroundImageError: (_, __) => const Icon(Icons.business, size: 40),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        org['public_name'] ?? org['company_name'] ?? 'Organizer',
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (org['verification_badge'] == true)
                                      const Icon(Icons.verified, color: Colors.blue, size: 24),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.orange, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${org['rating_average'] ?? '0.0'} (${org['total_reviews'] ?? 0} reviews)'),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.people, color: Colors.grey, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${org['total_followers'] ?? 0} followers'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (org['description'] != null)
                        Text(org['description'], style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      if (isLoggedIn)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: org['is_followed'] == true ? Colors.grey[300] : AppConstants.primaryColor,
                              foregroundColor: org['is_followed'] == true ? Colors.black : Colors.white,
                            ),
                            onPressed: () async {
                              if (org['is_followed'] == true) {
                                await provider.unfollowOrganizer(org['id']);
                              } else {
                                await provider.followOrganizer(org['id']);
                              }
                            },
                            child: Text(org['is_followed'] == true ? 'Following' : 'Follow Organizer'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (isLoggedIn)
                         SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              context.push('/organizers/${org['id']}/review');
                            },
                            child: const Text('Write a Review'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppConstants.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppConstants.primaryColor,
                    tabs: const [
                      Tab(text: 'Events'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventsList(provider),
                    _buildReviewsList(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventsList(PublicOrganizerProvider provider) {
    if (provider.organizerEvents.isEmpty) {
      return const Center(child: Text('No events available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.organizerEvents.length,
      itemBuilder: (context, index) {
        // Here we map dynamic array to Event model assuming EventCard can take raw map or we need to construct Event.
        // For simplicity, we just assume EventCard accepts an Event object, we might need to parse it.
        // I will use a simple list tile for events if EventCard requires a specific parsed model.
        final event = provider.organizerEvents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: event['banner_image'] != null
                ? Image.network(event['banner_image'], width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 50),
            title: Text(event['title'] ?? ''),
            subtitle: Text(event['date'] ?? ''),
            onTap: () {
              context.push('/event/${event['id']}');
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewsList(PublicOrganizerProvider provider) {
    if (provider.organizerReviews.isEmpty) {
      return const Center(child: Text('No reviews yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.organizerReviews.length,
      itemBuilder: (context, index) {
        final review = provider.organizerReviews[index];
        final user = review['user'] ?? {};
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(user['avatar'] ?? ''),
                      onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(user['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.orange,
                        );
                      }),
                    ),
                  ],
                ),
                if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(review['comment']),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool get holdFocus => false;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
