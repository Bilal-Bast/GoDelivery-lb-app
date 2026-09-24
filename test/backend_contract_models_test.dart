import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/admin_models.dart';
import 'package:godelivery_lb_app/models/district.dart';
import 'package:godelivery_lb_app/models/order.dart';

void main() {
  test('parses the compact backend order contract', () {
    final order = Order.fromJson({
      'id': 'ORD-1',
      'm': 'merchant-a',
      'driver': 'driver-a',
      'c': {
        'f': 'Maya',
        'l': 'Haddad',
        'p': '70123456',
        'loc': {'d': 'Beirut', 'cty': 'Achrafieh'},
      },
      'pr': {'t': 20, 'd': 3},
      's': 2,
      'createdAt': '2026-09-20T10:00:00.000Z',
      'statusUpdatedAt': '2026-09-20T11:00:00.000Z',
      'e': true,
      'eN': 'Call first',
    });

    expect(order.merchantId, 'merchant-a');
    expect(order.driverId, 'driver-a');
    expect(order.customerName, 'Maya Haddad');
    expect(order.district, 'Beirut');
    expect(order.city, 'Achrafieh');
    expect(order.status, 'PICKED_UP');
    expect(order.merchantAmount, 17);
  });

  test('parses the nested location response', () {
    final district = District.fromJson({
      'id': 'district-1',
      'district': {'en': 'Beirut', 'ar': 'بيروت'},
      'cities': [
        {'en': 'Achrafieh', 'ar': 'الأشرفية'},
      ],
    });

    expect(district.nameEn, 'Beirut');
    expect(district.cities.single.nameEn, 'Achrafieh');
    expect(district.cities.single.districtId, 'district-1');
  });

  test('parses analytics and finance dashboard responses', () {
    final analytics = AnalyticsOverview.fromJson({
      'summary': {
        'totalOrders': 12,
        'totalRevenue': 450,
        'ordersToday': 3,
        'activeDrivers': 2,
        'statusCounts': [1, 2, 3, 4, 1, 0, 1],
      },
    });
    final finance = FinanceOverview.fromJson({
      'merchants': [
        {
          'merchantUsername': 'shop',
          'merchantName': 'Shop Owner',
          'accountType': 'postpaid',
          'orderCount': 2,
          'balance': 80,
        },
      ],
      'drivers': [
        {
          'driverUsername': 'driver',
          'driverName': 'Driver One',
          'orderCount': 3,
          'outstanding': 120,
        },
      ],
      'totals': {
        'owedToMerchants': 80,
        'owedByMerchants': 0,
        'owedByDrivers': 120,
      },
    });

    expect(analytics.statusCounts[3], 4);
    expect(finance.merchants.single.balance, 80);
    expect(finance.drivers.single.balance, 120);
  });

  test('keeps nullable and missing compact order fields safe', () {
    final order = Order.fromJson({
      'id': 'ORD-NULLS',
      'c': null,
      'pr': null,
      's': null,
      'e': null,
      'createdAt': null,
      'statusUpdatedAt': null,
    });

    expect(order.customerName, isEmpty);
    expect(order.driverId, isNull);
    expect(order.total, 0);
    expect(order.deliveryCharge, 0);
    expect(order.isExpress, isFalse);
    expect(order.status, 'WAREHOUSE');
  });
}
