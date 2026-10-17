import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:godelivery_lb_app/models/dispatch_plan.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/screens/admin/dispatch_planning_screen.dart';
import 'package:godelivery_lb_app/screens/specialized_screens.dart';

Map<String, dynamic> boardJson(
    {bool withOrder = true, bool withDrivers = true}) {
  final workload = {
    'activeCount': 1,
    'waitingCount': 0,
    'warehouseCount': 0,
    'newCount': 0,
    'pickedUpCount': 1,
    'expressActiveCount': 0,
    'weightedUnits': 2,
  };
  Map<String, dynamic> driver(String id, String username, int score) => {
        'id': id,
        'username': username,
        'displayName': username,
        'score': score,
        'workload': workload,
        'liveTracking': {'isLive': false, 'updatedAt': null},
        'reasons': ['Balanced active workload'],
      };
  final drivers = withDrivers
      ? [driver('d1', 'driver-one', 100), driver('d2', 'driver-two', 140)]
      : <Map<String, dynamic>>[];
  final order = {
    'id': 'ORD-1',
    'status': 'NEW',
    'district': 'North',
    'city': 'Tripoli',
    'isExpress': true,
    'merchant': {'id': 'm1', 'username': 'shop', 'displayName': 'Shop One'},
    'createdAt': '2026-10-17T08:00:00.000Z',
    'updatedAt': '2026-10-17T08:30:00.000Z',
    'currentDriver': null,
    'recommendation': {
      'recommendedDriver': driver('d1', 'driver-one', 100),
      'alternatives': [driver('d2', 'driver-two', 140)],
      'reasons': ['Balanced active workload', 'Express order priority'],
    },
  };
  return {
    'page': 1,
    'pageSize': 50,
    'totalOrders': withOrder ? 1 : 0,
    'totalPages': 1,
    'hasPrevious': false,
    'hasNext': false,
    'liveTrackingEnabled': false,
    'drivers': drivers,
    'groups': withOrder
        ? [
            {
              'district': 'North',
              'cities': [
                {
                  'city': 'Tripoli',
                  'orderCount': 1,
                  'expressCount': 1,
                  'orders': [order],
                },
              ],
            },
          ]
        : [],
  };
}

void main() {
  test('Driver sequence keeps the order supplied by the server', () async {
    final provider = DriverProvider(
      sequenceLoader: () async => {
        'success': true,
        'data': {
          'sequence': [
            {
              'sequence': 1,
              'id': 'EXP-1',
              'status': 'Picked_up',
              'district': 'North',
              'city': 'Tripoli',
              'isExpress': true,
              'createdAt': '2026-10-17T08:00:00Z',
            },
            {
              'sequence': 2,
              'id': 'ORD-2',
              'status': 'NEW',
              'district': 'South',
              'city': 'Saida',
              'isExpress': false,
              'createdAt': '2026-10-17T07:00:00Z',
            },
          ],
        },
      },
    );
    await provider.fetchSuggestedSequence();
    expect(provider.sequenceError, isNull);
    expect(provider.suggestedSequence.map((order) => order.id),
        ['EXP-1', 'ORD-2']);
  });

  testWidgets(
      'Driver sequence is advisory and marks Express without mutating orders',
      (tester) async {
    final item = DriverSequenceItem(
      sequence: 1,
      id: 'EXP-1',
      status: 'Picked_up',
      district: 'North',
      city: 'Tripoli',
      isExpress: true,
      createdAt: DateTime.utc(2026, 10, 17),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            DriverSuggestedSequence(
              sequence: [item],
              isLoading: false,
            ),
          ],
        ),
      ),
    ));
    expect(find.text('Suggested delivery sequence'), findsOneWidget);
    expect(find.textContaining('#EXP-1'), findsOneWidget);
    expect(find.text('Express'), findsOneWidget);
    expect(find.textContaining('not a route or ETA'), findsOneWidget);
  });

  test(
      'dispatch board parser reads workload and area groups without coordinates',
      () {
    final board = DispatchBoard.fromJson(boardJson());
    final order = board.groups.single.cities.single.orders.single;
    expect(board.totalOrders, 1);
    expect(board.drivers.first.workload.weightedUnits, 2);
    expect(order.recommendation?.recommendedDriver?.username, 'driver-one');
    expect(order.updatedAt.toUtc(), DateTime.utc(2026, 10, 17, 8, 30));
    expect(boardJson().toString(), isNot(contains('latitude')));
  });

  testWidgets(
      'admin reviews first; cancel never assigns and confirm uses server suggestion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    var assignmentCalls = 0;
    var assignedUsername = '';
    final provider = DispatchPlanningProvider(
      boardLoader: (_) async => {'success': true, 'data': boardJson()},
      assigner: (id, username, updatedAt) async {
        assignmentCalls++;
        assignedUsername = username;
        expect(id, 'ORD-1');
        expect(updatedAt.toUtc(), DateTime.utc(2026, 10, 17, 8, 30));
        return {
          'success': true,
          'data': {'id': id}
        };
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: AdminDispatchPlanningScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(provider.error, isNull, reason: provider.error);
    expect(provider.board, isNotNull);
    expect(find.textContaining('ORD-1'), findsOneWidget);
    expect(find.text('Review assignment'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dispatch_review_ORD-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dispatch_assignment_review_dialog')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('dispatch_cancel_assignment')));
    await tester.pumpAndSettle();
    expect(assignmentCalls, 0);

    await tester.tap(find.byKey(const Key('dispatch_review_ORD-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dispatch_confirm_assignment')));
    await tester.pumpAndSettle();
    expect(assignmentCalls, 1);
    expect(assignedUsername, 'driver-one');
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('empty dispatch board explains no waiting orders and no drivers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    final provider = DispatchPlanningProvider(
      boardLoader: (_) async => {
        'success': true,
        'data': boardJson(withOrder: false, withDrivers: false),
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: AdminDispatchPlanningScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(provider.error, isNull, reason: provider.error);
    expect(provider.board, isNotNull);
    expect(find.text('No waiting orders'), findsOneWidget);
    expect(find.textContaining('No DRIVER accounts'), findsOneWidget);
    expect(find.byKey(const Key('dispatch_apply_filters')), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
      'dispatch filters and order cards remain usable on phone and desktop widths',
      (tester) async {
    final provider = DispatchPlanningProvider(
      boardLoader: (_) async => {'success': true, 'data': boardJson()},
    );
    for (final width in [390.0, 1280.0]) {
      await tester.binding.setSurfaceSize(Size(width, 1800));
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: AdminDispatchPlanningScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(4));
      expect(find.byKey(const Key('dispatch_order_ORD-1')), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
