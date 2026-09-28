import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/analytics_report.dart';
import 'package:godelivery_lb_app/providers/analytics_provider.dart';

Map<String, dynamic> payload(String start, int orders) => {
      'range': {
        'startDate': start,
        'endDate': start,
        'previousStartDate': start,
        'previousEndDate': start,
        'timezone': 'UTC',
        'basis': 'createdAt'
      },
      'summary': {'totalOrders': orders},
      'comparison': {
        'totalOrders': {
          'current': orders,
          'previous': 0,
          'change': orders,
          'percentChange': null
        }
      },
      'rawStatusDistribution': {'WAREHOUSE': orders},
      'trend': {'bucket': 'day', 'points': []},
      'merchants': [],
      'drivers': [],
      'regions': {'districts': [], 'cities': []},
      'finance': null,
      'financeScope': 'filtered',
    };

void main() {
  test('date presets and custom UTC dates map to query contract', () {
    expect(
        const AnalyticsQuery(preset: 'last7').parameters, {'preset': 'last7'});
    const custom = AnalyticsQuery(
        preset: 'custom',
        startDate: '2026-09-01',
        endDate: '2026-09-27',
        merchantId: 'm1',
        district: 'Beirut');
    expect(custom.parameters, {
      'startDate': '2026-09-01',
      'endDate': '2026-09-27',
      'merchantId': 'm1',
      'district': 'Beirut'
    });
    expect(custom.hasOrderFilters, isTrue);
  });

  test('parses empty chart, null previous comparison, and scoped finance', () {
    final report = AnalyticsReport.fromJson(payload('2026-09-27', 5));
    expect(report.value('totalOrders'), 5);
    expect(report.comparison['totalOrders']!.percentChange, isNull);
    expect(report.trend, isEmpty);
    expect(report.finance, isNull);
  });

  test('provider discards older filter response', () async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    var calls = 0;
    final provider = AnalyticsReportProvider(
        loader: (_) => ++calls == 1 ? first.future : second.future);
    final oldLoad = provider.load(const AnalyticsQuery(preset: 'last7'));
    final newLoad = provider.load(const AnalyticsQuery(preset: 'last30'));
    second.complete({'success': true, 'data': payload('2026-09-01', 30)});
    await newLoad;
    first.complete({'success': true, 'data': payload('2026-09-20', 7)});
    await oldLoad;
    expect(provider.report!.range.startDate, '2026-09-01');
    expect(provider.report!.value('totalOrders'), 30);
    provider.dispose();
  });

  test('merchant and driver statement models preserve recorded amounts', () {
    final merchant = StatementReport.fromJson({
      'kind': 'merchant',
      'identity': {
        'id': 'm1',
        'username': 'shop',
        'name': 'Shop',
        'accountType': 'PREPAID'
      },
      'range': {'startDate': '2026-09-01', 'endDate': '2026-09-27'},
      'summary': {'totalOrders': 1},
      'orders': [
        {'id': 'A1'}
      ],
      'activity': [
        {'number': 1, 'amountUSD': -5}
      ],
      'activityTotals': {'recordedPaymentsUSD': -5},
    });
    expect(merchant.accountType, 'PREPAID');
    expect(merchant.activityTotals['recordedPaymentsUSD'], -5);
    final driver = StatementReport.fromJson({
      'kind': 'driver',
      'identity': {'id': 'd1', 'username': 'driver'},
      'range': {'startDate': '2026-09-01', 'endDate': '2026-09-27'},
      'summary': {},
      'orders': [],
      'activity': [],
      'activityTotals': {
        'collectionGrossUSD': 100,
        'recordedDriverFeesUSD': 10,
        'netTransferredUSD': 90
      },
    });
    expect(driver.activityTotals['netTransferredUSD'], 90);
  });
}
