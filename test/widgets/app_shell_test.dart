import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/core/theme/app_theme.dart';
import 'package:godelivery_lb_app/models/user.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/widgets/app_shell.dart';
import 'package:provider/provider.dart';

void main() {
  User user(String role) => User(
        id: 'user-id',
        username: role.toLowerCase(),
        role: role,
        firstName: 'A very long first name for layout coverage',
        lastName: 'A very long last name for layout coverage',
      );

  Widget shellAt(String location) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AppShell(
          location: location,
          child: const ColoredBox(color: Colors.transparent),
        ),
      ),
    );
  }

  group('$AppShell', () {
    testWidgets('uses the expected navigation at every app breakpoint',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cases = <double, Type>{
        599: MobileRoleNavigation,
        600: MobileRoleNavigation,
        839: MobileRoleNavigation,
        840: CompactNavigationRail,
        1199: CompactNavigationRail,
        1200: ExpandedNavigationPanel,
      };

      for (final entry in cases.entries) {
        tester.view.physicalSize = Size(entry.key, 800);
        await tester.pumpWidget(shellAt('/home'));
        await tester.pump();

        expect(find.byType(entry.value), findsOneWidget,
            reason: 'width ${entry.key}');
        expect(tester.takeException(), isNull, reason: 'width ${entry.key}');
      }
    });

    testWidgets('keeps the mobile more menu scrollable in a short window',
        (tester) async {
      tester.view.physicalSize = const Size(600, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: MobileRoleNavigation(
              destinations: AppDestination.forUser(user('ADMIN')),
              location: '/home/admin/analytics',
            ),
          ),
        ),
      );

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.byType(MoreNavigationSheet), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('$AppDestination', () {
    test('exposes only role-specific navigation destinations', () {
      expect(
        AppDestination.forUser(user('DRIVER')).map((item) => item.path),
        [
          '/home/driver-orders',
          '/home/driver-collections',
          '/home/profile',
        ],
      );
      expect(
        AppDestination.forUser(user('MERCHANT')).map((item) => item.path),
        [
          '/home/merchant-balance',
          '/home/orders',
          '/home/create-order',
          '/home/merchant-payments',
          '/home/profile',
        ],
      );
      expect(
        AppDestination.forUser(user('ADMIN')).map((item) => item.path),
        isNot(contains('/home/driver-orders')),
      );
    });

    test('matches order details without selecting unrelated paths', () {
      final orders = AppDestination.forUser(user('MERCHANT'))
          .firstWhere((item) => item.path == '/home/orders');

      expect(orders.matches('/home/orders/order-123'), isTrue);
      expect(orders.matches('/home/create-order'), isFalse);
    });
  });
}
