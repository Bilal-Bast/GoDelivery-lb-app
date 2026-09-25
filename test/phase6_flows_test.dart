import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/core/routing/app_router.dart';
import 'package:godelivery_lb_app/models/public_tracking.dart';
import 'package:godelivery_lb_app/models/user.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/screens/admin/admin_settings_controls.dart';
import 'package:godelivery_lb_app/screens/public/tracking_screen.dart';
import 'package:godelivery_lb_app/services/api_service.dart';
import 'package:godelivery_lb_app/widgets/app_components.dart';
import 'package:provider/provider.dart';

void main() {
  test('USD formatter preserves values and has one negative style', () {
    expect(formatUsd(0), r'$0.00');
    expect(formatUsd(5), r'$5.00');
    expect(formatUsd(25.5), r'$25.50');
    expect(formatUsd(1250), r'$1,250.00');
    expect(formatUsd(-50), r'-$50.00');
  });

  test('delivery charge editor uses the exact backend region keys', () {
    expect(deliveryChargeRegions, [
      'Akkar',
      'Baalbek-Hermel',
      'Beirut',
      'Bekaa',
      'El Nabatieh',
      'Mount Lebanon',
      'North',
      'South',
    ]);
  });

  test('user create payload contains only supplied role fields', () {
    final driver = buildUserPayload(
      username: 'driver',
      email: 'driver@example.com',
      password: 'Secret1!',
      firstName: 'Driver',
      phone: '70123456',
      deliveryFee: 5,
    );
    expect(driver['deliveryFee'], 5);
    expect(driver.containsKey('accountType'), isFalse);

    final edit = buildUserPayload(
      username: 'merchant',
      email: 'm@example.com',
      firstName: 'Merchant',
      phone: '70111111',
      accountType: 'PREPAID',
    );
    expect(edit.containsKey('password'), isFalse);
    expect(edit['accountType'], 'prepaid');
  });

  test('tracking parsing normalizes backend status without finance metadata',
      () {
    final order = PublicTrackingOrder.fromJson({
      'id': 'o1',
      's': 2,
      'c': {
        'f': 'Maya',
        'l': 'Haddad',
        'p': '70123456',
        'loc': {'d': 'Beirut', 'cty': 'Hamra'},
      },
      'pr': {'t': 25},
      'driver': 'driver-one',
    });
    expect(order.status.label, 'Picked up');
    expect(order.total, 25);
  });

  test('tracking provider exposes not-found and successful states', () async {
    final missing = TrackingProvider(
        loader: (_) async => {
              'success': false,
              'statusCode': 404,
              'error': 'Order not found',
            });
    expect(await missing.track('missing'), isFalse);
    expect(missing.error, 'Order not found');

    final found = TrackingProvider(
        loader: (_) async => {
              'success': true,
              'data': {
                'id': 'o1',
                's': 3,
                'c': <String, dynamic>{},
                'pr': {'t': 25},
              },
            });
    expect(await found.track('o1'), isTrue);
    expect(found.order?.status.label, 'Delivered');
  });

  test('password provider sends exact forgot/reset values', () async {
    String? email;
    String? token;
    String? password;
    final provider = PasswordFlowProvider(
      forgot: (value) async {
        email = value;
        return {'success': true, 'message': 'If an account exists'};
      },
      reset: (tokenValue, passwordValue) async {
        token = tokenValue;
        password = passwordValue;
        return {'success': true, 'message': 'Reset'};
      },
    );
    expect(await provider.requestReset(' person@example.com '), isTrue);
    expect(email, 'person@example.com');
    expect(await provider.resetPassword('token-1', 'Secret1!'), isTrue);
    expect((token, password), ('token-1', 'Secret1!'));
  });

  test('only admin can route to user management', () {
    User user(String role) => User(
          id: role,
          username: role,
          role: role,
          firstName: role,
          lastName: '',
        );
    expect(AppRouter.homeForUser(user('admin')), '/home');
    expect(AppRouter.homeForUser(user('driver')), '/home/driver-orders');
    expect(AppRouter.homeForUser(user('merchant')), '/home/merchant-balance');
  });

  test('auth restore replaces cached identity with authoritative auth/me data',
      () async {
    var loads = 0;
    final provider = AuthProvider(
      sessionExists: () async => true,
      sessionValidator: () async => true,
      userLoader: () async {
        loads += 1;
        return {
          'id': 'u1',
          'username': 'person',
          'role': loads == 1 ? 'driver' : 'merchant',
          'firstName': 'Person',
          'lastName': '',
        };
      },
      clearSession: () async {},
    );
    await provider.restoreSession();
    expect(provider.currentUser?.role, 'merchant');
    expect(provider.isLoggedIn, isTrue);
  });

  test('failed session validation clears storage and returns to logged out',
      () async {
    var clears = 0;
    final provider = AuthProvider(
      sessionExists: () async => true,
      sessionValidator: () async => false,
      userLoader: () async => {
        'id': 'u1',
        'username': 'person',
        'role': 'admin',
        'firstName': 'Person',
        'lastName': '',
      },
      clearSession: () async => clears += 1,
    );
    await provider.restoreSession();
    expect(provider.isLoggedIn, isFalse);
    expect(provider.currentUser, isNull);
    expect(clears, 1);
  });

  testWidgets('public tracking renders USD and no admin finance controls',
      (tester) async {
    final provider = TrackingProvider(
        loader: (_) async => {
              'success': true,
              'data': {
                'id': 'o1',
                's': 3,
                'c': {
                  'f': 'Maya',
                  'loc': {'d': 'Beirut', 'cty': 'Hamra'},
                },
                'pr': {'t': 25},
                'driver': 'driver-one',
              },
            });
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TrackingScreen()),
      ),
    );
    await tester.enterText(find.byKey(const Key('tracking_order_id')), 'o1');
    await tester.tap(find.byKey(const Key('tracking_submit')));
    await tester.pumpAndSettle();
    expect(find.text(r'$25.00'), findsOneWidget);
    expect(find.textContaining('LBP'), findsNothing);
    expect(find.text('Financial operations'), findsNothing);
  });
}
