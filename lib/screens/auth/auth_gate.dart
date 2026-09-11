import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../driver/driver_dashboard.dart';
import '../merchant/merchant_dashboard.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthStorage _storage = AuthStorage();
  final AuthService _authService = AuthService();

  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await _storage.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _screen = const LoginScreen();
      });

      return;
    }

    try {
      final user = await _authService.getMe();

      if (!mounted) return;

      setState(() {
        _screen = _dashboardForRole(user.role);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _screen = const LoginScreen();
      });
    }
  }

  Widget _dashboardForRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const AdminDashboard();

      case 'DRIVER':
        return const DriverDashboard();

      case 'MERCHANT':
        return const MerchantDashboard();

      default:
        return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_screen == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _screen!;
  }
}