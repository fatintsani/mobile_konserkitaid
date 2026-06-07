import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:konserkita_mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/checkout_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/ticket_validation_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/organizer_provider.dart';
import 'providers/content_provider.dart';
import 'providers/refund_provider.dart';
import 'providers/payout_provider.dart';
import 'providers/seat_provider.dart';
import 'providers/review_provider.dart';
import 'providers/locale_provider.dart';
import 'services/local_notification_service.dart';
import 'routes/app_router.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FCMService().init();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => TicketValidationProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => OrganizerProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => RefundProvider()),
        ChangeNotifierProvider(create: (_) => PayoutProvider()),
        ChangeNotifierProvider(create: (_) => SeatProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const KonserKitaApp(),
    ),
  );
}

class KonserKitaApp extends StatefulWidget {
  const KonserKitaApp({super.key});

  @override
  State<KonserKitaApp> createState() => _KonserKitaAppState();
}

class _KonserKitaAppState extends State<KonserKitaApp> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    if (authProvider.isCheckingAuth) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
        ),
      );
    }

    return MaterialApp.router(
      title: 'KonserKita',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
        useMaterial3: true,
      ),
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
