import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/public/marketplace_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/orders/orders_screens.dart';
import '../../screens/orders/create_order_screen.dart';
import '../../screens/specialized_screens.dart';

class AppRouter {
  static GoRouter router(bool isLoggedIn) {
    return GoRouter(
      initialLocation: isLoggedIn ? '/home' : '/',
      redirect: (context, state) {
        // Add redirect logic if needed
        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/',
          name: 'marketplace',
          builder: (context, state) => const MarketplaceScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Home Routes
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const AdminDashboard(),
          routes: [
            // Orders
            GoRoute(
              path: 'orders',
              name: 'orders',
              builder: (context, state) => const OrdersScreen(),
            ),
            GoRoute(
              path: 'orders/:id',
              name: 'orderDetail',
              builder: (context, state) {
                final orderId = state.pathParameters['id']!;
                return OrderDetailScreen(orderId: orderId);
              },
            ),
            GoRoute(
              path: 'create-order',
              name: 'createOrder',
              builder: (context, state) => const CreateOrderScreen(),
            ),

            // Driver Routes
            GoRoute(
              path: 'driver-orders',
              name: 'driverOrders',
              builder: (context, state) => const DriverOrdersScreen(),
            ),
            GoRoute(
              path: 'driver-collections',
              name: 'driverCollections',
              builder: (context, state) => const DriverCollectionsScreen(),
            ),

            // Merchant Routes
            GoRoute(
              path: 'merchant-balance',
              name: 'merchantBalance',
              builder: (context, state) => const MerchantBalanceScreen(),
            ),
            GoRoute(
              path: 'merchant-payments',
              name: 'merchantPayments',
              builder: (context, state) => const MerchantPaymentsScreen(),
            ),

            // Profile & Settings
            GoRoute(
              path: 'profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),

        // Onboarding
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
      errorBuilder: (context, state) => const ErrorScreen(),
    );
  }
}

// Placeholder screens (to be implemented)
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Register')));
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Forgot Password')));
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Onboarding')));
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Error')));
}
