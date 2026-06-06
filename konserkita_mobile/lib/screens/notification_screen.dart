import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _handleNotificationTap(BuildContext context, notification) {
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    if (notification.type == 'payment_success' || notification.type == 'ticket_used') {
      context.push('/my-tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (provider.notifications.isNotEmpty && provider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tandai semua dibaca',
              onPressed: () {
                provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
                );
              },
            ),
        ],
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Belum ada notifikasi', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => context.read<NotificationProvider>().fetchNotifications(),
                      child: ListView.builder(
                        itemCount: provider.notifications.length,
                        itemBuilder: (context, index) {
                          final notif = provider.notifications[index];
                          return Dismissible(
                            key: Key(notif.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              provider.deleteNotification(notif.id);
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              tileColor: notif.isRead ? Colors.white : AppConstants.primaryColor.withValues(alpha: 0.05),
                              leading: CircleAvatar(
                                backgroundColor: notif.isRead ? Colors.grey[200] : AppConstants.primaryColor.withValues(alpha: 0.2),
                                child: Icon(
                                  notif.type == 'checkout' ? Icons.shopping_cart :
                                  notif.type == 'payment_success' ? Icons.payment :
                                  notif.type == 'ticket_used' ? Icons.qr_code_scanner : Icons.notifications,
                                  color: notif.isRead ? Colors.grey : AppConstants.primaryColor,
                                ),
                              ),
                              title: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(notif.message),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.createdAt,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () => _handleNotificationTap(context, notif),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
