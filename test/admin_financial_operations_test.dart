import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/financial_operations.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/screens/admin/admin_financial_operations.dart';

FinancialOperationsProvider _provider({
  Future<Map<String, dynamic>> Function(String)? collectionEligibility,
  Future<Map<String, dynamic>> Function(String, List<String>)?
      collectionPreview,
  Future<Map<String, dynamic>> Function(String, List<String>, String)?
      collectionCreator,
  Future<Map<String, dynamic>> Function(String)? paymentEligibility,
  Future<Map<String, dynamic>> Function(String, List<String>)? paymentPreview,
  Future<Map<String, dynamic>> Function(String, List<String>, String)?
      paymentCreator,
  Future<Map<String, dynamic>> Function(String, double, String)? prepaidCreator,
  Future<Map<String, dynamic>> Function(String)? returnEligibility,
  Future<Map<String, dynamic>> Function(String, List<String>, String)?
      returnCreator,
}) =>
    FinancialOperationsProvider(
      collectionEligibility: collectionEligibility ??
          (_) async => {
                'success': true,
                'data': {'orders': <dynamic>[]}
              },
      collectionPreviewLoader: collectionPreview ??
          (_, __) async => {
                'success': true,
                'data': {
                  'orderCount': 0,
                  'grossAmount': 0,
                  'deliveryFeeTotal': 0,
                  'netAmount': 0,
                  'orders': <dynamic>[],
                },
              },
      collectionCreator:
          collectionCreator ?? (_, __, ___) async => {'success': true},
      paymentEligibility: paymentEligibility ??
          (_) async => {
                'success': true,
                'data': {'orders': <dynamic>[]}
              },
      paymentPreviewLoader: paymentPreview ??
          (_, __) async => {
                'success': true,
                'data': {
                  'orderCount': 0,
                  'grossAmount': 0,
                  'deliveryCharges': 0,
                  'amount': 0,
                  'orders': <dynamic>[],
                },
              },
      paymentCreator: paymentCreator ?? (_, __, ___) async => {'success': true},
      prepaidCreator: prepaidCreator ?? (_, __, ___) async => {'success': true},
      returnEligibility: returnEligibility ??
          (_) async => {
                'success': true,
                'data': <dynamic>[],
                'merchant': {'accountType': 'POSTPAID'},
              },
      returnCreator: returnCreator ?? (_, __, ___) async => {'success': true},
      collectionHistoryLoader: () async => {'success': true, 'data': []},
      paymentHistoryLoader: () async => {'success': true, 'data': []},
      returnHistoryLoader: () async => {'success': true, 'data': []},
    );

void main() {
  test('collection eligibility and authoritative preview are parsed', () async {
    final provider = _provider(
      collectionEligibility: (_) async => {
        'success': true,
        'data': {
          'orders': [
            {
              'id': 'o1',
              'status': 'DELIVERED',
              'total': 100,
              'deliveryCharge': 10,
              'collectionValue': 100,
              'driverFee': 5,
            },
          ],
        },
      },
      collectionPreview: (_, ids) async => {
        'success': true,
        'data': {
          'orderCount': ids.length,
          'grossAmount': 100,
          'deliveryFeeTotal': 5,
          'netAmount': 95,
          'orders': <dynamic>[],
        },
      },
    );
    expect(await provider.loadCollectionEligibility('driver'), isTrue);
    expect(provider.collectionOrders.single.settlementValue, 100);
    provider.toggleCollection('o1');
    expect(await provider.previewSelectedCollection('driver'), isTrue);
    expect(provider.collectionPreview?.grossAmount, 100);
    expect(provider.collectionPreview?.deductions, 5);
    expect(provider.collectionPreview?.netAmount, 95);
  });

  test('POSTPAID payment preview uses server payout values', () async {
    final provider = _provider(
      paymentEligibility: (_) async => {
        'success': true,
        'data': {
          'orders': [
            {
              'id': 'o1',
              'total': 100,
              'deliveryCharge': 10,
              'payable': 90,
            },
          ],
        },
      },
      paymentPreview: (_, ids) async => {
        'success': true,
        'data': {
          'orderCount': ids.length,
          'grossAmount': 100,
          'deliveryCharges': 10,
          'amount': 90,
          'orders': <dynamic>[],
        },
      },
    );
    await provider.loadPaymentEligibility('merchant');
    provider.togglePayment('o1');
    await provider.previewSelectedPayment('merchant');
    expect(provider.paymentPreview?.netAmount, 90);
  });

  test('duplicate collection submission is prevented', () async {
    final gate = Completer<Map<String, dynamic>>();
    var creates = 0;
    final provider = _provider(
      collectionCreator: (_, __, ___) {
        creates += 1;
        return gate.future;
      },
    );
    provider.selectedCollectionIds.add('o1');
    final first = provider.createSelectedCollection('driver');
    final second = provider.createSelectedCollection('driver');
    expect(await second, isFalse);
    expect(creates, 1);
    gate.complete({'success': true});
    expect(await first, isTrue);
  });

  test('stale collection rejection keeps error and refreshes eligibility',
      () async {
    var refreshes = 0;
    final provider = _provider(
      collectionEligibility: (_) async {
        refreshes += 1;
        return {
          'success': true,
          'data': {'orders': <dynamic>[]}
        };
      },
      collectionCreator: (_, __, ___) async => {
        'success': false,
        'statusCode': 409,
        'error': 'Order o1 is already collected',
      },
    );
    provider.selectedCollectionIds.add('o1');
    expect(await provider.createSelectedCollection('driver'), isFalse);
    expect(refreshes, 1);
    expect(
        provider.errorFor('collectionCreate'), contains('already collected'));
  });

  test('return eligibility preserves account type and physical value',
      () async {
    final provider = _provider(
      returnEligibility: (_) async => {
        'success': true,
        'data': [
          {
            'id': 'o1',
            'customerName': 'Maya Haddad',
            'reason': 'Cancelled by Customer',
            'goodsValue': 90,
            'isExchange': false,
            'cancelledBy': 'customer',
          },
        ],
        'merchant': {'accountType': 'PREPAID'},
      },
    );
    expect(await provider.loadReturnEligibility('merchant'), isTrue);
    expect(provider.returnAccountType, 'PREPAID');
    expect(provider.returnableOrders.single.goodsValue, 90);
  });

  test('positive and negative PREPAID amounts are submitted without sign flips',
      () async {
    final amounts = <double>[];
    final provider = _provider(
      prepaidCreator: (_, amount, __) async {
        amounts.add(amount);
        return {'success': true};
      },
    );
    expect(await provider.createPrepaidAdjustment('merchant', 50), isTrue);
    expect(await provider.createPrepaidAdjustment('merchant', -20), isTrue);
    expect(amounts, [50, -20]);
  });

  test('settlement preview models retain money semantics', () {
    final collection = SettlementPreview.collection({
      'orderCount': 2,
      'grossAmount': 110,
      'deliveryFeeTotal': 10,
      'netAmount': 100,
      'orders': <dynamic>[],
    });
    final payment = SettlementPreview.payment({
      'orderCount': 1,
      'grossAmount': 100,
      'deliveryCharges': 10,
      'amount': 90,
      'orders': <dynamic>[],
    });
    expect(
        (collection.grossAmount, collection.deductions, collection.netAmount),
        (110, 10, 100));
    expect((payment.grossAmount, payment.deductions, payment.netAmount),
        (100, 10, 90));
  });

  testWidgets('non-admin users cannot see settlement controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminFinancialOperations(
            admin: AdminProvider(),
            isAdmin: false,
            onRefresh: () async {},
          ),
        ),
      ),
    );
    expect(find.text('Financial operations'), findsNothing);
    expect(find.text('Review collection'), findsNothing);
  });
}
