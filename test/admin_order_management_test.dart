import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:godelivery_lb_app/models/order.dart';
import 'package:godelivery_lb_app/models/order_status.dart';
import 'package:godelivery_lb_app/models/user.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/screens/orders/orders_screens.dart';
import 'package:godelivery_lb_app/services/api_service.dart';

Map<String, dynamic> _orderJson({
  String status = 'NEW',
  String driver = 'driver-one',
}) =>
    {
      'id': 'order-1',
      'm': 'merchant-one',
      'driver': driver,
      'c': {
        'f': 'Maya',
        'l': 'Haddad',
        'p': '70123456',
        'loc': {'d': 'Beirut', 'cty': 'Hamra'},
      },
      'pr': {'t': 100, 'd': 10},
      's': status,
      'e': true,
      'eN': 'Call first',
      'cancelledBy': status == 'CANCELLED' ? 'customer' : null,
      'cancelledFromStatus': status == 'CANCELLED' ? 'Picked_up' : null,
      'settlement': {'collectionCount': 0, 'paymentCount': 0},
      'createdAt': '2026-09-24T10:00:00.000Z',
      'updatedAt': '2026-09-24T11:00:00.000Z',
      'statusUpdatedAt': '2026-09-24T11:00:00.000Z',
    };

Map<String, dynamic> _historyResult() => {
      'success': true,
      'data': [
        {
          'id': 'history-1',
          'action_type': 'update',
          'new_value': {'driver': 'driver-two'},
          'performed_by': 'admin',
          'metadata': {},
          'created_at': '2026-09-24T12:00:00.000Z',
        },
      ],
    };

void main() {
  test('manual admin statuses exclude settlement-generated states', () {
    expect(adminOperationalStatuses, contains(OrderStatusValue.delivered));
    expect(
        adminOperationalStatuses, isNot(contains(OrderStatusValue.collected)));
    expect(adminOperationalStatuses, isNot(contains(OrderStatusValue.paid)));
  });

  test('order list uses centralized statuses and combined filters', () {
    expect(
      orderStatusFilters,
      ['ALL', ...OrderStatusValue.values.skip(1).map((status) => status.code)],
    );
    final orders = [
      Order.fromJson(_orderJson()),
      Order.fromJson({
        ..._orderJson(status: 'DELIVERED', driver: 'driver-two'),
        'id': 'order-2',
        'm': 'merchant-two',
      }),
    ];
    expect(
      filterAdminOrders(
        orders,
        status: 'DELIVERED',
        driver: 'driver-two',
        merchant: 'merchant-two',
        search: 'order-2',
      ).single.id,
      'order-2',
    );
    expect(filterAdminOrders(orders, search: 'missing'), isEmpty);
  });

  test('driver assignment choices contain DRIVER accounts only', () {
    final users = [
      User(
        id: 'd1',
        username: 'driver',
        role: 'driver',
        firstName: 'Driver',
        lastName: 'One',
      ),
      User(
        id: 'm1',
        username: 'merchant',
        role: 'merchant',
        firstName: 'Merchant',
        lastName: 'One',
      ),
      User(
        id: 'a1',
        username: 'admin',
        role: 'admin',
        firstName: 'Admin',
        lastName: 'One',
      ),
    ];

    expect(adminDriverChoices(users).map((user) => user.username), ['driver']);
  });

  test('edit payload contains only changed permitted fields', () {
    final original = Order.fromJson(_orderJson());
    final payload = buildAdminOrderUpdatePayload(
      original: original,
      merchantUsername: original.merchantId,
      customerFirstName: original.customerFirstName,
      customerLastName: original.customerLastName!,
      customerPhone: '03123456',
      district: original.district,
      city: original.city,
      total: original.total,
      deliveryCharge: original.deliveryCharge,
      isExpress: original.isExpress,
      expressNote: original.expressNote,
    );

    expect(payload, {
      'c': {'p': '03123456'},
    });
    expect(payload, isNot(contains('s')));
    expect(payload, isNot(contains('driver')));
  });

  test('create contract includes authoritative names, express and driver', () {
    final payload = buildCreateOrderPayload(
      orderId: 'GD-1',
      merchantUsername: 'merchant-one',
      customerFirstName: 'Maya',
      customerPhone: '70123456',
      district: 'Beirut',
      city: 'Hamra',
      total: 100,
      deliveryCharge: 10,
      isExpress: true,
      expressNote: 'Call first',
      driverUsername: 'driver-one',
    );

    expect(payload['m'], 'merchant-one');
    expect(payload['driver'], 'driver-one');
    expect(payload['e'], true);
    expect(payload['eN'], 'Call first');
    expect((payload['c'] as Map)['loc'], {'d': 'Beirut', 'cty': 'Hamra'});
  });

  test('reassignment updates authoritative detail and refreshes history',
      () async {
    var historyReads = 0;
    var assignedDriver = 'driver-one';
    final provider = OrderProvider(
      orderLoader: (_) async => {
        'success': true,
        'data': _orderJson(driver: assignedDriver),
      },
      orderUpdater: (id, changes) async {
        assignedDriver = changes['driver'] as String;
        return {
          'success': true,
          'data': _orderJson(driver: assignedDriver),
        };
      },
      historyLoader: (_) async {
        historyReads++;
        return _historyResult();
      },
    );
    await provider.fetchOrder('order-1');

    expect(
      await provider.updateOrder('order-1', {'driver': 'driver-two'}),
      isTrue,
    );
    expect(provider.selectedOrder!.driverId, 'driver-two');
    expect(historyReads, 1);
    expect(provider.history.single.performedBy, 'admin');
  });

  test('reassignment rejection refreshes authoritative order', () async {
    var reads = 0;
    final provider = OrderProvider(
      orderLoader: (_) async => {
        'success': true,
        'data':
            _orderJson(driver: reads++ == 0 ? 'driver-one' : 'driver-server'),
      },
      orderUpdater: (_, __) async => {
        'success': false,
        'statusCode': 409,
        'error': 'Assignment is no longer allowed',
      },
    );
    await provider.fetchOrder('order-1');

    expect(
      await provider.updateOrder('order-1', {'driver': 'driver-two'}),
      isFalse,
    );
    expect(provider.error, 'Assignment is no longer allowed');
    expect(provider.selectedOrder!.driverId, 'driver-server');
  });

  test('409 delete rejection retains and refreshes the order', () async {
    final provider = OrderProvider(
      orderLoader: (_) async => {'success': true, 'data': _orderJson()},
      orderDeleter: (_) async => {
        'success': false,
        'statusCode': 409,
        'error': 'Order is linked to financial records',
      },
    );
    await provider.fetchOrder('order-1');

    expect(await provider.deleteOrder('order-1'), isFalse);
    expect(provider.selectedOrder, isNotNull);
    expect(provider.error, 'Order is linked to financial records');
  });

  test('cancellation backend error refreshes authoritative state', () async {
    var reads = 0;
    final provider = OrderProvider(
      orderLoader: (_) async => {
        'success': true,
        'data': _orderJson(status: reads++ == 0 ? 'NEW' : 'PICKED_UP'),
      },
      orderCanceller: (_, __) async => {
        'success': false,
        'statusCode': 409,
        'error': 'Order was settled by another operator',
      },
    );
    await provider.fetchOrder('order-1');

    expect(await provider.cancelOrder('order-1', 'customer'), isFalse);
    expect(provider.error, 'Order was settled by another operator');
    expect(provider.selectedOrder!.status, 'PICKED_UP');
  });

  test('eligible deletion removes authoritative detail', () async {
    final provider = OrderProvider(
      orderLoader: (_) async => {'success': true, 'data': _orderJson()},
      orderDeleter: (_) async => {'success': true},
    );
    await provider.fetchOrder('order-1');

    expect(await provider.deleteOrder('order-1'), isTrue);
    expect(provider.selectedOrder, isNull);
  });

  test('duplicate admin mutations send one request', () async {
    final response = Completer<Map<String, dynamic>>();
    var requests = 0;
    final provider = OrderProvider(
      orderLoader: (_) async => {
        'success': true,
        'data': _orderJson(driver: 'driver-two'),
      },
      orderUpdater: (_, __) {
        requests++;
        return response.future;
      },
      historyLoader: (_) async => {'success': true, 'data': []},
    );

    final first = provider.updateOrder('order-1', {'driver': 'driver-two'});
    final second = provider.updateOrder('order-1', {'driver': 'driver-three'});
    expect(await second, isFalse);
    expect(requests, 1);
    response
        .complete({'success': true, 'data': _orderJson(driver: 'driver-two')});
    expect(await first, isTrue);
    expect(requests, 1);
  });

  test('history loading exposes success, empty and error states', () async {
    final success = OrderProvider(historyLoader: (_) async => _historyResult());
    await success.fetchHistory('order-1');
    expect(success.history.single.actionType, 'update');
    expect(success.historyError, isNull);

    final empty = OrderProvider(
      historyLoader: (_) async => {'success': true, 'data': []},
    );
    await empty.fetchHistory('order-1');
    expect(empty.history, isEmpty);

    final error = OrderProvider(
      historyLoader: (_) async => {
        'success': false,
        'error': 'History unavailable',
      },
    );
    await error.fetchHistory('order-1');
    expect(error.historyError, 'History unavailable');
  });

  testWidgets('settled orders expose no manual financial lifecycle actions',
      (tester) async {
    final settled = Order.fromJson({
      ..._orderJson(status: 'COLLECTED'),
      'settlement': {'collectionCount': 1, 'paymentCount': 0},
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdminOrderControls(
          order: settled,
          updating: false,
          onEdit: () {},
          onAssign: () {},
          onStatus: () {},
          onCancel: () {},
          onDelete: () {},
        ),
      ),
    ));

    expect(find.byKey(const Key('admin_change_status')), findsNothing);
    expect(find.byKey(const Key('admin_assign_driver')), findsNothing);
    expect(find.byKey(const Key('admin_cancel_order')), findsNothing);
    expect(find.byKey(const Key('admin_delete_order')), findsNothing);
    expect(find.textContaining('settlement records'), findsOneWidget);
  });

  testWidgets('cancellation requires explicit attribution confirmation',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AdminCancellationDialog()),
    ));

    expect(find.text('Cancel order?'), findsOneWidget);
    expect(find.byKey(const Key('cancel_by_merchant')), findsOneWidget);
    expect(find.byKey(const Key('cancel_by_customer')), findsOneWidget);
    expect(find.text('Keep order'), findsOneWidget);
  });
}
