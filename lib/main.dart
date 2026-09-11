import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';

void main() {
  runApp(const GoDeliveryApp());
}

class GoDeliveryApp extends StatelessWidget {
  const GoDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoDelivery',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}