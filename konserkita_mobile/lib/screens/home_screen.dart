import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();
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
      body: eventProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventProvider.error != null
              ? Center(child: Text(eventProvider.error!))
              : RefreshIndicator(
                  onRefresh: () => context.read<EventProvider>().fetchEvents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: eventProvider.events.length,
                    itemBuilder: (context, index) {
                      return EventCard(event: eventProvider.events[index]);
                    },
                  ),
                ),
    );
  }
}
