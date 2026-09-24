import 'package:flutter/material.dart';

import '../specialized_screens.dart';

/// Backward-compatible merchant dashboard entry point.
class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context) => const MerchantBalanceScreen();
}
