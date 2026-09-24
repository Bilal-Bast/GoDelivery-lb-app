import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/driver_stats.dart';
import 'package:godelivery_lb_app/models/order.dart';
import 'package:godelivery_lb_app/models/order_status.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/screens/orders/orders_screens.dart';
import 'package:godelivery_lb_app/screens/specialized_screens.dart';

Map<String, dynamic> orderJson(String status) => {
      'id': 'order-1',
      'm': 'merchant-one',
      'driver': 'driver-one',
      'c': {
        'f': 'Test',
        'l': 'Customer',
        'p': '70123456',
        'loc': {'d': 'Beirut', 'cty': 'Beirut'},
      },
      'pr': {'t': 100000, 'd': 10000},
      's': status,
      'createdAt': '2026-09-24T10:00:00.000Z',
      'statusUpdatedAt': '2026-09-24T10:00:00.000Z',
    };

Order order(String status) => Order.fromJson(orderJson(status));

Widget surface(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  group('central order status and role actions', () {
    test('normalizes backend numeric and string representations', () {
      expect(OrderStatusValue.fromBackend(0), OrderStatusValue.warehouse);
      expect(
          OrderStatusValue.fromBackend('Picked_up'), OrderStatusValue.pickedUp);
      expect(
          OrderStatusValue.fromBackend('Canceled'), OrderStatusValue.cancelled);
      expect(OrderStatusValue.fromBackend(5), OrderStatusValue.paid);
      expect(
          OrderStatusValue.fromBackend('unexpected'), OrderStatusValue.unknown);
    });

    test('parses the driver stats response contract', () {
      final stats = DriverStats.fromJson({
        'totalDeliveries': 12,
        'todaysDeliveries': 2,
        'activeOrders': 3,
      });
      expect(stats.totalDeliveries, 12);
      expect(stats.todaysDeliveries, 2);
      expect(stats.activeOrders, 3);
    });

    test('matches the role and status action matrix', () {
      for (final status in [
        OrderStatusValue.warehouse,
        OrderStatusValue.newOrder,
      ]) {
        expect(
          availableOrderActions(role: 'driver', status: status),
          [OrderMutationAction.pickUp],
        );
      }
      expect(
        availableOrderActions(
          role: 'driver',
          status: OrderStatusValue.pickedUp,
        ),
        [OrderMutationAction.deliver, OrderMutationAction.cancel],
      );
      for (final status in [
        OrderStatusValue.delivered,
        OrderStatusValue.cancelled,
        OrderStatusValue.collected,
        OrderStatusValue.paid,
      ]) {
        expect(
          availableOrderActions(role: 'driver', status: status),
          isEmpty,
        );
      }
      for (final status in OrderStatusValue.values) {
        expect(
          availableOrderActions(role: 'merchant', status: status),
          isEmpty,
        );
      }
      expect(
        availableOrderActions(
          role: 'admin',
          status: OrderStatusValue.newOrder,
        ),
        [OrderMutationAction.deliver],
      );
    });
  });

  group('driver action rendering', () {
    testWidgets('NEW and WAREHOUSE show only Pick Up', (tester) async {
      for (final status in ['NEW', 'WAREHOUSE']) {
        await tester.pumpWidget(surface(DriverDeliveryCard(
          order: order(status),
          updating: false,
          onAction: (_) {},
        )));
        expect(find.text('Pick Up'), findsOneWidget);
        expect(find.text('Delivered'), findsNothing);
        expect(find.text('Cancelled'), findsNothing);
      }
    });

    testWidgets('PICKED_UP shows delivery and cancellation', (tester) async {
      await tester.pumpWidget(surface(DriverDeliveryCard(
        order: order('PICKED_UP'),
        updating: false,
        onAction: (_) {},
      )));
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Pick Up'), findsNothing);
    });

    testWidgets('terminal states show no mutation actions', (tester) async {
      for (final status in ['DELIVERED', 'CANCELLED', 'COLLECTED', 'PAID']) {
        await tester.pumpWidget(surface(DriverDeliveryCard(
          order: order(status),
          updating: false,
          onAction: (_) {},
        )));
        expect(find.byKey(const Key('driver_order-1_pickUp')), findsNothing);
        expect(find.byKey(const Key('driver_order-1_deliver')), findsNothing);
        expect(find.byKey(const Key('driver_order-1_cancel')), findsNothing);
      }
    });

    testWidgets('merchant detail is informational and admin action remains',
        (tester) async {
      await tester.pumpWidget(surface(OrderDetailContent(
        order: order('NEW'),
        role: 'merchant',
        showHeaderAction: true,
        updating: false,
        onAction: (_) {},
      )));
      expect(find.text('Pick Up'), findsNothing);
      expect(find.text('Mark as delivered'), findsNothing);

      await tester.pumpWidget(surface(OrderDetailContent(
        order: order('NEW'),
        role: 'admin',
        showHeaderAction: true,
        updating: false,
        onAction: (_) {},
      )));
      expect(find.text('Mark as delivered'), findsOneWidget);
    });

    testWidgets('driver stats render the existing backend fields',
        (tester) async {
      await tester.pumpWidget(surface(DriverOrdersHeader(
        selectedStatus: 'ALL',
        orders: const [],
        stats: const DriverStats(
          totalDeliveries: 12,
          todaysDeliveries: 2,
          activeOrders: 3,
        ),
        onStatusChanged: (_) {},
        onRefresh: () async {},
      )));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('driver provider mutations', () {
    test('pickup, delivery and cancellation update local state', () async {
      for (final change in [
        ('NEW', 'PICKED_UP'),
        ('PICKED_UP', 'DELIVERED'),
        ('PICKED_UP', 'CANCELLED'),
      ]) {
        final provider = DriverProvider(
          ordersLoader: () async => {
            'success': true,
            'data': [orderJson(change.$1)],
          },
          statusUpdater: (id, status, note) async => {
            'success': true,
            'data': orderJson(change.$2),
          },
          statsLoader: () async => const DriverStats(
            totalDeliveries: 1,
            todaysDeliveries: 1,
            activeOrders: 0,
          ),
        );
        await provider.fetchDriverOrders();
        expect(await provider.updateOrderStatus('order-1', change.$2), isTrue);
        expect(provider.driverOrders.single.status, change.$2);
      }
    });

    test('failed mutation reloads authoritative state and keeps API error',
        () async {
      var reads = 0;
      final provider = DriverProvider(
        ordersLoader: () async => {
          'success': true,
          'data': [orderJson(reads++ == 0 ? 'NEW' : 'PICKED_UP')],
        },
        statusUpdater: (id, status, note) async => {
          'success': false,
          'error': 'Order status changed on the server',
        },
      );
      await provider.fetchDriverOrders();

      expect(await provider.updateOrderStatus('order-1', 'PICKED_UP'), isFalse);
      expect(provider.error, 'Order status changed on the server');
      expect(provider.driverOrders.single.status, 'PICKED_UP');
    });

    test('duplicate submissions produce one request', () async {
      final response = Completer<Map<String, dynamic>>();
      var requests = 0;
      final provider = DriverProvider(
        statusUpdater: (id, status, note) {
          requests++;
          return response.future;
        },
        statsLoader: () async => const DriverStats(
          totalDeliveries: 0,
          todaysDeliveries: 0,
          activeOrders: 0,
        ),
      );

      final first = provider.updateOrderStatus('order-1', 'PICKED_UP');
      final second = provider.updateOrderStatus('order-1', 'PICKED_UP');
      expect(await second, isFalse);
      expect(requests, 1);
      response.complete({
        'success': true,
        'data': orderJson('PICKED_UP'),
      });
      expect(await first, isTrue);
      expect(requests, 1);
    });
  });
}
