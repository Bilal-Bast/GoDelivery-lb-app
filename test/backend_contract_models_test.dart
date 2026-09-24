import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/admin_models.dart';
import 'package:godelivery_lb_app/models/district.dart';
import 'package:godelivery_lb_app/models/collection.dart';
import 'package:godelivery_lb_app/models/finance.dart';
import 'package:godelivery_lb_app/models/order.dart';
import 'package:godelivery_lb_app/models/payment.dart';
import 'package:godelivery_lb_app/models/user.dart';

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

  test('parses scoped collection history and pagination', () {
    final page = DriverCollectionPage.fromJson({
      'data': [
        {
          'id': 'collection-1',
          'number': 7,
          'amount': 120,
          'deliveryFee': 10,
          'createdAt': '2026-09-20T10:00:00.000Z',
          'admin': {'id': 'a1', 'username': 'admin'},
          'orders': [
            {'id': 'o1', 'total': 120, 'deliveryCharge': 10},
          ],
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
    });

    expect(page.data.single.number, 7);
    expect(page.data.single.orders.single.id, 'o1');
    expect(page.data.single.admin?.username, 'admin');
    expect(page.pagination.totalPages, 1);
  });

  test('parses settlement, advance, and negative payment history records', () {
    final page = MerchantPaymentPage.fromJson({
      'data': [
        {
          'id': 'advance-1',
          'number': 8,
          'amount': 50,
          'isAdvance': true,
          'createdAt': '2026-09-20T10:00:00.000Z',
          'orders': [],
        },
        {
          'id': 'adjustment-1',
          'number': 9,
          'amount': -15,
          'isAdvance': true,
          'createdAt': '2026-09-21T10:00:00.000Z',
          'orders': [],
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 2, 'totalPages': 1},
    });

    expect(page.data.first.isAdvance, isTrue);
    expect(page.data.first.orderCount, 0);
    expect(page.data.last.amount, -15);
  });

  test('parses prepaid and postpaid authoritative balances', () {
    final prepaid = MerchantBalance.fromJson({
      'role': 'merchant',
      'accountType': 'PREPAID',
      'entitled': 200,
      'paid': 75,
      'balance': 125,
      'orderCount': 3,
    });
    final postpaid = MerchantBalance.fromJson({
      'role': 'merchant',
      'accountType': 'POSTPAID',
      'entitled': 90,
      'paid': 0,
      'balance': 90,
      'orderCount': 1,
    });

    expect(prepaid.accountType, 'PREPAID');
    expect(prepaid.balance, 125);
    expect(postpaid.accountType, 'POSTPAID');
    expect(postpaid.entitled, 90);
  });

  test('keeps nullable account profile fields safe', () {
    final user = User.fromJson({
      'id': 'm1',
      'username': 'merchant',
      'role': 'merchant',
      'email': null,
      'phone': null,
      'accountType': null,
      'paymentDay': null,
      'orderIdPrefix': null,
      'deliveryFee': null,
      'legacyBalance': null,
      'deliveryCharges': null,
    });

    expect(user.email, isNull);
    expect(user.deliveryFee, isNull);
    expect(user.deliveryCharges, isEmpty);
    expect(user.legacyBalance, 0);
  });
}
