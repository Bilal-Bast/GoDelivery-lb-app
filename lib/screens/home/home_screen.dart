import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../admin/admin_dashboard.dart';
import '../public/marketplace_screen.dart';
import '../specialized_screens.dart';

/// Compatibility entry point for callers that still construct `HomeScreen`
/// directly. Role routing normally happens in `AppRouter`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user?.isAdmin ?? false) return const AdminDashboard();
    if (user?.isDriver ?? false) return const DriverOrdersScreen();
    if (user?.isMerchant ?? false) return const MerchantBalanceScreen();
    return const MarketplaceScreen();
  }
}
