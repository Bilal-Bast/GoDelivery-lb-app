import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/providers/analytics_provider.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/screens/admin/advanced_analytics_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'analytics shows KPI comparison and an empty chart on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final analytics = AnalyticsReportProvider(
        loader: (_) async => {
              'success': true,
              'data': {
                'range': {
                  'startDate': '2026-09-01',
                  'endDate': '2026-09-27',
                  'previousStartDate': '2026-08-05',
                  'previousEndDate': '2026-08-31',
                  'timezone': 'UTC',
                  'basis': 'createdAt'
                },
                'summary': {
                  'totalOrders': 5,
                  'deliveredOrders': 3,
                  'cancelledOrders': 1,
                  'activeOrders': 1,
                  'grossOrderValueUSD': 100,
                  'deliveryChargesUSD': 10,
                  'averageOrderValueUSD': 20,
                  'expressOrders': 1,
                  'collectedOrders': 1,
                  'paidOrders': 1,
                  'deliverySuccessRate': .6,
                  'cancellationRate': .2,
                  'expressRate': .2
                },
                'comparison': {
                  'totalOrders': {
                    'current': 5,
                    'previous': 0,
                    'change': 5,
                    'percentChange': null
                  }
                },
                'rawStatusDistribution': {
                  'WAREHOUSE': 1,
                  'NEW': 0,
                  'Picked_up': 0,
                  'DELIVERED': 2,
                  'Canceled': 1,
                  'Paid': 1,
                  'COLLECTED': 0
                },
                'trend': {'bucket': 'day', 'points': []},
                'merchants': [],
                'drivers': [],
                'regions': {'districts': [], 'cities': []},
                'finance': null,
                'financeScope': 'Clear filters',
              }
            });
    await analytics.load();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AnalyticsReportProvider>.value(
              value: analytics),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: const MaterialApp(
            home: Scaffold(body: AdvancedAnalyticsPage(onRefresh: _refresh)))));
    await tester.pumpAndSettle();
    expect(find.text('Orders created'), findsOneWidget);
    expect(find.textContaining('n/a (previous 0)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    analytics.dispose();
  });
}

Future<void> _refresh() async {}
