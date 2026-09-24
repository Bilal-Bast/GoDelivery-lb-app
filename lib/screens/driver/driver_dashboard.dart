import 'package:flutter/material.dart';

import '../specialized_screens.dart';

/// Backward-compatible driver dashboard entry point.
class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) => const DriverOrdersScreen();
}
