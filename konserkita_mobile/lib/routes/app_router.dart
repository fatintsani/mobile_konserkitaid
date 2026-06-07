import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/my_tickets_screen.dart';
import '../screens/ticket_selection_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/payment_webview_screen.dart';
import '../screens/payment_status_screen.dart';
import '../screens/ticket_detail_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/scan_result_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/preferences_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/transaction_history_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/search_event_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/organizer_dashboard_screen.dart';
import '../screens/organizer_event_list_screen.dart';
import '../screens/organizer_event_detail_screen.dart';
import '../screens/organizer_sales_screen.dart';
import '../screens/organizer_attendees_screen.dart';
import '../screens/organizer_event_form_screen.dart';
import '../screens/organizer_ticket_type_manage_screen.dart';
import '../screens/refund_request_screen.dart';
import '../screens/my_refunds_screen.dart';
import '../screens/refund_detail_screen.dart';
import '../screens/organizer_payout_balance_screen.dart';
import '../screens/organizer_payout_request_screen.dart';
import '../screens/organizer_payout_history_screen.dart';
import '../screens/organizer_payout_detail_screen.dart';
import '../models/event.dart';
import '../models/transaction.dart';
import '../screens/seat_map_screen.dart';
import '../screens/review_form_screen.dart';
import '../screens/event_reviews_screen.dart';
import '../screens/my_reviews_screen.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const QRScannerScreen(),
        redirect: (context, state) {
          final authProvider = context.read<AuthProvider>();
          final role = authProvider.user?.role;
          if (role != 'organizer' && role != 'admin' && role != 'super_admin') {
            return '/';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/scan-result',
        builder: (context, state) => const ScanResultScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/my-tickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/my-tickets/:code',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return TicketDetailScreen(ticketCode: code);
        },
      ),
      GoRoute(
        path: '/event/:id/tickets',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TicketSelectionScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/event/:id/seat-map',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SeatMapScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/event/:id/reviews',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EventReviewsScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/event/:id/write-review',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ReviewFormScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/payment-webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentWebViewScreen(
            paymentUrl: extra?['paymentUrl'] ?? '',
            transactionId: extra?['transactionId'] ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/payment-status',
        builder: (context, state) {
          final extra = state.extra as int?;
          return PaymentStatusScreen(transactionId: extra);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/my-reviews',
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TransactionDetailScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchEventScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/refund-request',
        builder: (context, state) {
          final transaction = state.extra as Transaction;
          return RefundRequestScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: '/my-refunds',
        builder: (context, state) => const MyRefundsScreen(),
      ),
      GoRoute(
        path: '/my-refunds/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RefundDetailScreen(refundId: id);
        },
      ),
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerDashboardScreen(),
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/events',
        builder: (context, state) => const OrganizerEventListScreen(),
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/events/create',
        builder: (context, state) => const OrganizerEventFormScreen(),
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/events/:id/edit',
        builder: (context, state) {
          final event = state.extra as Event?;
          return OrganizerEventFormScreen(event: event);
        },
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/events/:id/ticket-types',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrganizerTicketTypeManageScreen(eventId: id);
        },
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/events/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrganizerEventDetailScreen(eventId: id);
        },
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/events/:id/sales',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrganizerSalesScreen(eventId: id);
        },
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/events/:id/attendees',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrganizerAttendeesScreen(eventId: id);
        },
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/payouts/balance',
        builder: (context, state) => const OrganizerPayoutBalanceScreen(),
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/payouts/request',
        builder: (context, state) => const OrganizerPayoutRequestScreen(),
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/payouts/history',
        builder: (context, state) => const OrganizerPayoutHistoryScreen(),
        redirect: _organizerGuard,
      ),
      GoRoute(
        path: '/organizer/payouts/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrganizerPayoutDetailScreen(payoutId: id);
        },
        redirect: _organizerGuard,
      ),
    ],
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      
      return null;
    },
  );

  static String? _organizerGuard(BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final role = authProvider.user?.role;
    if (role != 'organizer' && role != 'admin' && role != 'super_admin') {
      return '/';
    }
    return null;
  }
}
