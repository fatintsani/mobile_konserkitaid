import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/content_provider.dart';
import '../widgets/event_card.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents();
      context.read<ContentProvider>().fetchContent();
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final contentProvider = context.watch<ContentProvider>();
    final user = authProvider.user;
    final isOrganizerOrAdmin = user?.role == 'organizer' || user?.role == 'admin' || user?.role == 'super_admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('KonserKita'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          if (authProvider.isAuthenticated)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => context.push('/notifications'),
                ),
                if (notificationProvider.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppConstants.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${notificationProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          if (isOrganizerOrAdmin)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push('/scanner'),
            ),
          IconButton(
            icon: const Icon(Icons.confirmation_number),
            onPressed: () => context.push('/my-tickets'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ContentProvider>().fetchContent();
          await context.read<EventProvider>().fetchEvents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!contentProvider.isLoading && contentProvider.banners.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    itemCount: contentProvider.banners.length,
                    itemBuilder: (context, index) {
                      final banner = contentProvider.banners[index];
                      return Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(banner['image_url']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (!contentProvider.isLoading && contentProvider.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: contentProvider.categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Chip(
                                avatar: category['icon'] != null ? CircleAvatar(backgroundImage: NetworkImage(category['icon'])) : null,
                                label: Text(category['name']),
                                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              if (eventProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (eventProvider.error != null)
                Center(child: Padding(padding: EdgeInsets.all(32), child: Text(eventProvider.error!)))
              else if (eventProvider.events.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No events found.')))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: eventProvider.events.length,
                  itemBuilder: (context, index) {
                    return EventCard(event: eventProvider.events[index]);
                  },
                ),
                
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
