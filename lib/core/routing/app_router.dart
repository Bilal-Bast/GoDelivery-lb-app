import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/providers.dart';
import '../../screens/public/marketplace_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_section_screen.dart';
import '../../screens/orders/orders_screens.dart';
import '../../screens/orders/create_order_screen.dart';
import '../../screens/specialized_screens.dart';

class AppRouter {
  static const String authLoadingPath = '/auth-loading';
  static const String adminHomePath = '/home';
  static const String driverHomePath = '/home/driver-orders';
  static const String merchantHomePath = '/home/merchant-balance';

  static GoRouter router(
    AuthProvider authProvider, {
    String initialLocation = authLoadingPath,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: authProvider,
      redirect: (context, state) {
        return redirectFor(authProvider, state.matchedLocation);
      },
      routes: [
        GoRoute(
          path: authLoadingPath,
          name: 'authLoading',
          builder: (context, state) => const AuthLoadingScreen(),
        ),

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
            GoRoute(
              path: 'admin/users',
              name: 'adminUsers',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.users,
              ),
            ),
            GoRoute(
              path: 'admin/drivers',
              name: 'adminDrivers',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.drivers,
              ),
            ),
            GoRoute(
              path: 'admin/analytics',
              name: 'adminAnalytics',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.analytics,
              ),
            ),
            GoRoute(
              path: 'admin/finance',
              name: 'adminFinance',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.finance,
              ),
            ),
            GoRoute(
              path: 'admin/locations',
              name: 'adminLocations',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.locations,
              ),
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

  static String? redirectFor(AuthProvider authProvider, String location) {
    if (authProvider.isInitializing) {
      return location == authLoadingPath ? null : authLoadingPath;
    }

    if (location == authLoadingPath) {
      return authProvider.isLoggedIn
          ? homeForUser(authProvider.currentUser)
          : '/';
    }

    final isProtected =
        location == adminHomePath || location.startsWith('$adminHomePath/');

    if (!isProtected) {
      if (location == '/login' && authProvider.isLoggedIn) {
        return homeForUser(authProvider.currentUser);
      }
      return null;
    }

    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      return '/login';
    }

    if (_canAccess(authProvider.currentUser!, location)) {
      return null;
    }

    return homeForUser(authProvider.currentUser);
  }

  static String homeForUser(User? user) {
    if (user?.isAdmin ?? false) return adminHomePath;
    if (user?.isDriver ?? false) return driverHomePath;
    if (user?.isMerchant ?? false) return merchantHomePath;
    return '/';
  }

  static bool _canAccess(User user, String location) {
    final isSharedProfileRoute =
        location == '/home/profile' || location == '/home/settings';
    final isOrderRoute =
        location == '/home/orders' || location.startsWith('/home/orders/');
    final isCreateOrderRoute = location == '/home/create-order';
    final isDriverRoute =
        location == driverHomePath || location == '/home/driver-collections';
    final isMerchantRoute =
        location == merchantHomePath || location == '/home/merchant-payments';
    final isAdminRoute = location.startsWith('/home/admin/');

    final hasProtectedRole = user.isAdmin || user.isDriver || user.isMerchant;
    if (isSharedProfileRoute) return hasProtectedRole;

    if (user.isAdmin) {
      return location == adminHomePath ||
          isOrderRoute ||
          isCreateOrderRoute ||
          isAdminRoute;
    }

    if (user.isDriver) return isDriverRoute;

    if (user.isMerchant) {
      return isMerchantRoute || isOrderRoute || isCreateOrderRoute;
    }

    return false;
  }
}

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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
