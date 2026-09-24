import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:godelivery_lb_app/models/collection.dart';
import 'package:godelivery_lb_app/models/finance.dart';
import 'package:godelivery_lb_app/models/payment.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/screens/specialized_screens.dart';

const emptyPagination = Pagination(
  page: 1,
  limit: 20,
  total: 0,
  totalPages: 0,
);

Widget testApp({
  required Widget child,
  DriverProvider? driverProvider,
  MerchantProvider? merchantProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      if (driverProvider != null)
        ChangeNotifierProvider.value(value: driverProvider),
      if (merchantProvider != null)
        ChangeNotifierProvider.value(value: merchantProvider),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  test('driver provider keeps empty history and authoritative zero balance',
      () async {
    final provider = DriverProvider(
      collectionsLoader: () async => const DriverCollectionPage(
        data: [],
        pagination: emptyPagination,
      ),
      balanceLoader: () async => const DriverBalance(
        gross: 0,
        feeTotal: 0,
        outstanding: 0,
        orderCount: 0,
      ),
    );

    await Future.wait([provider.fetchCollections(), provider.fetchBalance()]);

    expect(provider.collections, isEmpty);
    expect(provider.balance?.outstanding, 0);
    expect(provider.error, isNull);
  });

  test('providers expose API errors instead of fake finance values', () async {
    final driver = DriverProvider(
      collectionsLoader: () async => throw Exception('forbidden'),
      balanceLoader: () async => throw Exception('server failure'),
    );
    final merchant = MerchantProvider(
      balanceLoader: () async => throw Exception('unauthorized'),
      paymentsLoader: () async => throw Exception('malformed response'),
    );

    await Future.wait([driver.fetchCollections(), driver.fetchBalance()]);
    await Future.wait([merchant.fetchBalance(), merchant.fetchPayments()]);

    expect(driver.error, contains('forbidden'));
    expect(driver.balance, isNull);
    expect(driver.balanceError, contains('server failure'));
    expect(merchant.balance, isNull);
    expect(merchant.error, contains('malformed response'));
  });

  testWidgets('driver collections screen shows loading then empty history',
      (tester) async {
    final collections = Completer<DriverCollectionPage>();
    final provider = DriverProvider(
      collectionsLoader: () => collections.future,
      balanceLoader: () async => const DriverBalance(
        gross: 0,
        feeTotal: 0,
        outstanding: 0,
        orderCount: 0,
      ),
    );

    await tester.pumpWidget(testApp(
      child: const DriverCollectionsScreen(),
      driverProvider: provider,
    ));
    await tester.pump();
    expect(find.textContaining('Loading collections'), findsOneWidget);

    collections.complete(const DriverCollectionPage(
      data: [],
      pagination: emptyPagination,
    ));
    await tester.pumpAndSettle();
    expect(find.text('No collections yet'), findsOneWidget);
    expect(find.byKey(const Key('driver_outstanding_balance')), findsOneWidget);
  });

  testWidgets('driver collections screen renders API error and retry',
      (tester) async {
    final provider = DriverProvider(
      collectionsLoader: () async => throw Exception('request failed'),
      balanceLoader: () async => const DriverBalance(
        gross: 0,
        feeTotal: 0,
        outstanding: 0,
        orderCount: 0,
      ),
    );
    await tester.pumpWidget(testApp(
      child: const DriverCollectionsScreen(),
      driverProvider: provider,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Collection history is not available'), findsOneWidget);
    expect(find.textContaining('request failed'), findsOneWidget);
  });

  testWidgets(
      'merchant balance screen uses MerchantProvider without OrderProvider',
      (tester) async {
    final provider = MerchantProvider(
      balanceLoader: () async => const MerchantBalance(
        accountType: 'PREPAID',
        entitled: 200,
        paid: 75,
        balance: 125,
        orderCount: 3,
      ),
      paymentsLoader: () async => const MerchantPaymentPage(
        data: [],
        pagination: emptyPagination,
      ),
    );

    await tester.pumpWidget(testApp(
      child: const MerchantBalanceScreen(),
      merchantProvider: provider,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('merchant_authoritative_balance')),
        findsOneWidget);
    expect(find.text('PREPAID ACCOUNT'), findsOneWidget);
    expect(find.textContaining('125'), findsWidgets);
  });

  testWidgets('merchant payments screen shows an empty scoped history',
      (tester) async {
    final provider = MerchantProvider(
      balanceLoader: () async => const MerchantBalance(
        accountType: 'POSTPAID',
        entitled: 0,
        paid: 0,
        balance: 0,
        orderCount: 0,
      ),
      paymentsLoader: () async => const MerchantPaymentPage(
        data: [],
        pagination: emptyPagination,
      ),
    );

    await tester.pumpWidget(testApp(
      child: const MerchantPaymentsScreen(),
      merchantProvider: provider,
    ));
    await tester.pumpAndSettle();

    expect(find.text('No payments yet'), findsOneWidget);
  });
}
