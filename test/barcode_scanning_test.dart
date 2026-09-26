import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/core/scanning/order_code_parser.dart';
import 'package:godelivery_lb_app/models/driver_stats.dart';
import 'package:godelivery_lb_app/providers/providers.dart';

Map<String, dynamic> _order(String id) => {
      'id': id,
      'm': 'merchant-one',
      'driver': 'driver-one',
      'c': {
        'f': 'Test',
        'p': '70123456',
        'loc': {'d': 'Beirut', 'cty': 'Beirut'},
      },
      'pr': {'t': 100, 'd': 10},
      's': 'NEW',
      'createdAt': '2026-09-24T10:00:00.000Z',
      'statusUpdatedAt': '2026-09-24T10:00:00.000Z',
    };

FinancialOperationsProvider _operations() => FinancialOperationsProvider(
      collectionEligibility: (_) async => {
        'success': true,
        'data': {
          'orders': [
            {
              'id': 'COLLECT-1',
              'status': 'DELIVERED',
              'total': 100,
              'deliveryCharge': 10,
              'collectionValue': 100,
              'driverFee': 5,
            },
          ],
        },
      },
      returnEligibility: (_) async => {
        'success': true,
        'data': [
          {
            'id': 'RETURN-1',
            'customerName': 'Test Customer',
            'reason': 'Cancelled by Customer',
            'goodsValue': 90,
            'isExchange': false,
          },
        ],
        'merchant': {'accountType': 'POSTPAID'},
      },
      collectionHistoryLoader: () async => {'success': true, 'data': []},
      paymentHistoryLoader: () async => {'success': true, 'data': []},
      returnHistoryLoader: () async => {'success': true, 'data': []},
    );

void main() {
  group('central order-code parser', () {
    const parser = OrderCodeParser();

    test('accepts the plain authoritative order ID and trims edges', () {
      final result = parser.parse('  ORD-123_ABC  ');
      expect(result.isValid, isTrue);
      expect(result.orderId, 'ORD-123_ABC');
    });

    test('rejects empty, control-character and overlong input', () {
      expect(parser.parse('  ').error, OrderCodeError.empty);
      expect(parser.parse('bad\nid').error, OrderCodeError.malformed);
      expect(parser.parse(List.filled(51, 'x').join()).error,
          OrderCodeError.tooLong);
    });

    test('does not guess URL or prefix transformations', () {
      expect(
        parser.parse('https://example.com/orders/ORD-1').error,
        OrderCodeError.malformed,
      );
    });
  });

  test('scan gate accepts one frame until explicitly re-armed', () {
    final gate = ScanGate();
    expect(gate.tryLock(), isTrue);
    expect(gate.tryLock(), isFalse);
    gate.finish();
    expect(gate.tryLock(), isFalse);
    gate.rearm();
    expect(gate.tryLock(), isTrue);
  });

  test('driver scan uses authoritative lookup and never mutates status',
      () async {
    var lookups = 0;
    var mutations = 0;
    final provider = DriverProvider(
      orderLoader: (id) async {
        lookups += 1;
        return {'success': true, 'data': _order(id)};
      },
      statusUpdater: (id, status, note) async {
        mutations += 1;
        return {'success': true, 'data': _order(id)};
      },
      statsLoader: () async => const DriverStats(
        totalDeliveries: 0,
        todaysDeliveries: 0,
        activeOrders: 0,
      ),
    );
    final order = await provider.lookupAssignedOrder('ORDER-1');
    expect(order?.id, 'ORDER-1');
    expect(lookups, 1);
    expect(mutations, 0);
  });

  test('driver scan preserves backend authorization error', () async {
    final provider = DriverProvider(
      orderLoader: (_) async => {
        'success': false,
        'statusCode': 404,
        'error': 'Order not found',
      },
    );
    expect(await provider.lookupAssignedOrder('OTHER-DRIVER'), isNull);
    expect(provider.error, 'Order not found');
  });

  test('collection scan adds eligible ID once and rejects wrong context',
      () async {
    final provider = _operations();
    await provider.loadCollectionEligibility('driver-one');
    expect(provider.selectCollectionByScan('COLLECT-1'),
        ScanSelectionResult.added);
    expect(provider.selectCollectionByScan('COLLECT-1'),
        ScanSelectionResult.alreadySelected);
    expect(provider.selectCollectionByScan('OTHER-DRIVER'),
        ScanSelectionResult.notEligible);
    expect(provider.selectedCollectionIds, {'COLLECT-1'});
  });

  test('return scan adds authoritative eligible ID once', () async {
    final provider = _operations();
    await provider.loadReturnEligibility('merchant-one');
    expect(provider.selectReturnByScan('RETURN-1'), ScanSelectionResult.added);
    expect(provider.selectReturnByScan('RETURN-1'),
        ScanSelectionResult.alreadySelected);
    expect(provider.selectReturnByScan('NOT-RETURNABLE'),
        ScanSelectionResult.notEligible);
    expect(provider.selectedReturnIds, {'RETURN-1'});
  });
}
