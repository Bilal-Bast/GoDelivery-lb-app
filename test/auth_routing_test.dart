import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:godelivery_lb_app/core/routing/app_router.dart';
import 'package:godelivery_lb_app/providers/providers.dart';

void main() {
  Future<AuthProvider> restoreUser(String role) async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'cached-access-token',
      'refresh_token': 'cached-refresh-token',
      'user_data': jsonEncode({
        'id': 'user-1',
        'username': role.toLowerCase(),
        'role': role,
        'firstName': 'Test',
        'lastName': role,
      }),
    });

    final authProvider = AuthProvider();
    await authProvider.restoreSession(refreshAccessToken: false);
    return authProvider;
  }

  test('logged-out users cannot access protected admin routes', () async {
    SharedPreferences.setMockInitialValues({});
    final authProvider = AuthProvider();
    await authProvider.restoreSession(refreshAccessToken: false);

    expect(
      AppRouter.redirectFor(authProvider, AppRouter.adminHomePath),
      '/login',
    );
  });

  test('public and onboarding routes remain public when logged out', () async {
    SharedPreferences.setMockInitialValues({});
    final authProvider = AuthProvider();
    await authProvider.restoreSession(refreshAccessToken: false);

    for (final location in [
      '/',
      '/login',
      '/register',
      '/forgot-password',
      '/onboarding',
    ]) {
      expect(AppRouter.redirectFor(authProvider, location), isNull,
          reason: location);
    }
  });

  test('ADMIN resolves to and can access the admin home', () async {
    final authProvider = await restoreUser('ADMIN');

    expect(
      AppRouter.redirectFor(authProvider, '/login'),
      AppRouter.adminHomePath,
    );
    expect(
      AppRouter.redirectFor(authProvider, AppRouter.adminHomePath),
      isNull,
    );
    for (final location in [
      '/home/orders',
      '/home/orders/order-123',
      '/home/create-order',
      '/home/admin/users',
      '/home/admin/merchants',
      '/home/admin/drivers',
      '/home/admin/analytics',
      '/home/admin/finance',
      '/home/admin/locations',
    ]) {
      expect(AppRouter.redirectFor(authProvider, location), isNull,
          reason: location);
    }
  });

  test('DRIVER resolves to and can access driver routes', () async {
    final authProvider = await restoreUser('DRIVER');

    expect(
      AppRouter.redirectFor(authProvider, '/login'),
      AppRouter.driverHomePath,
    );
    expect(
      AppRouter.redirectFor(authProvider, '/home/driver-collections'),
      isNull,
    );
  });

  test('MERCHANT resolves to and can access merchant routes', () async {
    final authProvider = await restoreUser('MERCHANT');

    expect(
      AppRouter.redirectFor(authProvider, '/login'),
      AppRouter.merchantHomePath,
    );
    expect(
      AppRouter.redirectFor(authProvider, '/home/merchant-payments'),
      isNull,
    );
    expect(
        AppRouter.redirectFor(authProvider, '/home/orders/order-123'), isNull);
    expect(AppRouter.redirectFor(authProvider, '/home/create-order'), isNull);
  });

  test('cross-role protected navigation redirects to the user home', () async {
    final driver = await restoreUser('DRIVER');
    expect(
      AppRouter.redirectFor(driver, AppRouter.adminHomePath),
      AppRouter.driverHomePath,
    );

    final merchant = await restoreUser('MERCHANT');
    expect(
      AppRouter.redirectFor(merchant, AppRouter.driverHomePath),
      AppRouter.merchantHomePath,
    );

    final admin = await restoreUser('ADMIN');
    expect(
      AppRouter.redirectFor(admin, AppRouter.merchantHomePath),
      AppRouter.adminHomePath,
    );
  });

  test('logout clears cached authentication and protected access', () async {
    final authProvider = await restoreUser('ADMIN');

    await authProvider.logout();

    final preferences = await SharedPreferences.getInstance();
    expect(authProvider.status, AuthStatus.unauthenticated);
    expect(preferences.getString('auth_token'), isNull);
    expect(preferences.getString('refresh_token'), isNull);
    expect(preferences.getString('user_data'), isNull);
    expect(
      AppRouter.redirectFor(authProvider, AppRouter.adminHomePath),
      '/login',
    );
  });

  test('cached user restoration preserves role and correct home', () async {
    final authProvider = await restoreUser('DRIVER');

    expect(authProvider.status, AuthStatus.authenticated);
    expect(authProvider.currentUser?.role, 'DRIVER');
    expect(
      AppRouter.redirectFor(authProvider, AppRouter.authLoadingPath),
      AppRouter.driverHomePath,
    );
  });

  test('normal authenticated users cannot enter role-protected routes',
      () async {
    final authProvider = await restoreUser('USER');

    expect(
      AppRouter.redirectFor(authProvider, AppRouter.adminHomePath),
      '/',
    );
    expect(AppRouter.redirectFor(authProvider, '/home/profile'), '/');
  });
}
