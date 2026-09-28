import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/analytics_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';
import 'models/app_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  final authProvider = AuthProvider();

  runApp(MyApp(authProvider: authProvider));
  await authProvider.restoreSession();
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  late final router = AppRouter.router(authProvider);
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final NotificationService notifications = NotificationService(
    auth: authProvider,
    navigate: (route) => router.go(route),
    present: (AppNotification item) => messengerKey.currentState?.showSnackBar(
      SnackBar(
          content: Text(item.body),
          action: item.id == 'debug-preview'
              ? null
              : SnackBarAction(
                  label: 'Open', onPressed: () => notifications.open(item))),
    ),
  )..initialize();

  MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: notifications),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => MerchantProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsReportProvider()),
        ChangeNotifierProvider(create: (_) => FinancialOperationsProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => PasswordFlowProvider()),
      ],
      child: MaterialApp.router(
        scaffoldMessengerKey: messengerKey,
        title: 'GoDelivery',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
