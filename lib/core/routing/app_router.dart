import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/providers.dart';
import '../../screens/public/marketplace_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/password_screens.dart';
import '../../screens/public/tracking_screen.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_section_screen.dart';
import '../../screens/orders/orders_screens.dart';
import '../../screens/orders/create_order_screen.dart';
import '../../screens/specialized_screens.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/app_components.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/godelivery_logo.dart';

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
        GoRoute(
          path: '/reset-password',
          name: 'resetPassword',
          builder: (context, state) => ResetPasswordScreen(
            token: state.uri.queryParameters['token'] ?? '',
          ),
        ),
        GoRoute(
          path: '/track',
          name: 'tracking',
          builder: (context, state) => TrackingScreen(
            initialOrderId: state.uri.queryParameters['id'] ?? '',
          ),
        ),

        // Authenticated role-aware application shell.
        ShellRoute(
          builder: (context, state, child) => AppShell(
            location: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const AdminDashboard(),
            ),
            GoRoute(
              path: '/home/orders',
              name: 'orders',
              builder: (context, state) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'orderDetail',
                  builder: (context, state) => OrderDetailScreen(
                    orderId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/home/create-order',
              name: 'createOrder',
              builder: (context, state) => const CreateOrderScreen(),
            ),
            GoRoute(
              path: '/home/admin/users',
              name: 'adminUsers',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.users,
              ),
            ),
            GoRoute(
              path: '/home/admin/merchants',
              name: 'adminMerchants',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.merchants,
              ),
            ),
            GoRoute(
              path: '/home/admin/drivers',
              name: 'adminDrivers',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.drivers,
              ),
            ),
            GoRoute(
              path: '/home/admin/analytics',
              name: 'adminAnalytics',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.analytics,
              ),
            ),
            GoRoute(
              path: '/home/admin/finance',
              name: 'adminFinance',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.finance,
              ),
            ),
            GoRoute(
              path: '/home/admin/locations',
              name: 'adminLocations',
              builder: (context, state) => const AdminSectionScreen(
                section: AdminSection.locations,
              ),
            ),
            GoRoute(
              path: '/home/driver-orders',
              name: 'driverOrders',
              builder: (context, state) => const DriverOrdersScreen(),
            ),
            GoRoute(
              path: '/home/driver-collections',
              name: 'driverCollections',
              builder: (context, state) => const DriverCollectionsScreen(),
            ),
            GoRoute(
              path: '/home/merchant-balance',
              name: 'merchantBalance',
              builder: (context, state) => const MerchantBalanceScreen(),
            ),
            GoRoute(
              path: '/home/merchant-payments',
              name: 'merchantPayments',
              builder: (context, state) => const MerchantPaymentsScreen(),
            ),
            GoRoute(
              path: '/home/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/home/settings',
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
  Widget build(BuildContext context) => const Scaffold(
        body: AppLoadingState(message: 'Restoring your session…'),
      );
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => PublicMessageScreen(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Account requests',
        message:
            'GoDelivery accounts are currently created by the operations team. Contact your administrator to request access.',
        actionLabel: 'Back to sign in',
        onAction: () => context.go('/login'),
      );
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => PublicMessageScreen(
        icon: Icons.rocket_launch_outlined,
        title: 'Welcome to GoDelivery',
        message:
            'Your delivery workspace is ready. Sign in to continue with your assigned role.',
        actionLabel: 'Continue',
        onAction: () => context.go('/login'),
      );
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) => PublicMessageScreen(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message:
            'The page you requested does not exist or is no longer available.',
        actionLabel: 'Go to marketplace',
        onAction: () => context.go('/'),
      );
}

class PublicMessageScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const PublicMessageScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppSurfaceCard(
                emphasized: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GoDeliveryLogo(height: 42),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.brandSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.brandStrong, size: 34),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.textStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(onPressed: onAction, child: Text(actionLabel)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
