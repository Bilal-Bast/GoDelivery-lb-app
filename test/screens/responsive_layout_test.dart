import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/core/theme/app_theme.dart';
import 'package:godelivery_lb_app/models/admin_models.dart';
import 'package:godelivery_lb_app/models/order.dart';
import 'package:godelivery_lb_app/models/payment.dart';
import 'package:godelivery_lb_app/screens/admin/admin_dashboard.dart';
import 'package:godelivery_lb_app/screens/admin/admin_section_screen.dart';
import 'package:godelivery_lb_app/screens/orders/orders_screens.dart';
import 'package:godelivery_lb_app/screens/specialized_screens.dart';

void main() {
  final longOrder = Order(
    id: 'ORDER-WITH-A-VERY-LONG-IDENTIFIER-1234567890',
    merchantId: 'merchant-with-a-very-long-username@example.com',
    driverId: 'driver-with-a-very-long-username@example.com',
    customerFirstName: 'Customer with an exceptionally long first name',
    customerLastName: 'and an exceptionally long last name',
    customerPhone: '+961 70 123 456 extension 123456',
    district: 'A district with an exceptionally long localized name',
    city: 'A city with an exceptionally long localized name',
    total: 999999999999999,
    deliveryCharge: 999999999,
    status: 'PICKED_UP',
    createdAt: DateTime(2026, 9, 24, 12, 30),
    statusUpdatedAt: DateTime(2026, 9, 24, 13, 30),
    isExpress: true,
    expressNote:
        'A long express note that must wrap instead of overflowing the card.',
  );

  Widget testSurface(Widget child) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );

  group('compact long-content layouts', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('order cards handle long identifiers, names, and amounts',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final variants = <Widget>[
        MobileOrderCard(order: longOrder),
        DriverDeliveryCard(
          order: longOrder,
          updating: false,
          onDelivered: () {},
          onCancelled: () {},
        ),
        MerchantOrderRow(order: longOrder),
        RecentOrderMobileRow(order: longOrder),
        MerchantPaymentCard(
          payment: MerchantPayment(
            id: 'payment-id',
            merchantId: 'merchant-id',
            merchantName: 'Merchant with a very long name',
            number: 999999,
            amount: 999999999999999,
            status: 'PAID',
            notes: 'A long payment note that should wrap safely.',
            createdAt: DateTime(2026, 9, 24),
            isAdvance: false,
            orderCount: 999,
          ),
        ),
      ];

      for (final variant in variants) {
        await tester.pumpWidget(testSurface(variant));
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: variant.runtimeType.toString());
      }
    });

    testWidgets('finance rows handle long names and large balances',
        (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const balance = FinancePartyBalance(
        username: 'merchant-with-a-very-long-username@example.com',
        name: 'Merchant with an exceptionally long display name',
        orderCount: 999999,
        balance: 999999999999999,
      );
      await tester.pumpWidget(
        testSurface(
          const BalanceRow(
            row: balance,
            icon: Icons.storefront_outlined,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
