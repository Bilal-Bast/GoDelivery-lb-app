import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'providers/providers.dart';

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

  MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => MerchantProvider()),
      ],
      child: MaterialApp.router(
        title: 'GoDelivery',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
