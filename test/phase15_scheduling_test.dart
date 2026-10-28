import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/core/time/schedule_time.dart';
import 'package:godelivery_lb_app/models/dispatch_plan.dart';
import 'package:godelivery_lb_app/models/order.dart';
import 'package:godelivery_lb_app/models/public_tracking.dart';
import 'package:godelivery_lb_app/models/schedule_board.dart';
import 'package:godelivery_lb_app/screens/orders/orders_screens.dart';
import 'package:godelivery_lb_app/services/api_service.dart';
import 'package:godelivery_lb_app/widgets/schedule_window_picker.dart';

Map<String, dynamic> _orderJson({
  Object? start,
  Object? end,
  String? state,
}) =>
    {
      'id': 'GD-15',
      'm': 'merchant-one',
      's': 1,
      'c': {
        'f': 'Maya',
        'l': 'K',
        'p': '70123456',
        'loc': {'d': 'Baabda', 'cty': 'Hazmieh'},
      },
      'pr': {'t': 25, 'd': 5},
      'createdAt': '2026-10-28T08:00:00.000Z',
      'statusUpdatedAt': '2026-10-28T08:00:00.000Z',
      'scheduledWindowStart': start,
      'scheduledWindowEnd': end,
      if (state != null) 'scheduleState': state,
    };

void main() {
  group('Beirut schedule time', () {
    test('normal winter date converts with Lebanon standard time', () {
      final window = ScheduleTime.fromLocal(
        date: DateTime(2026, 1, 15),
        startHour: 14,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
      );
      expect(window.start, DateTime.utc(2026, 1, 15, 12));
      expect(window.end, DateTime.utc(2026, 1, 15, 15));
    });

    test('normal summer date converts with Lebanon daylight time', () {
      final window = ScheduleTime.fromLocal(
        date: DateTime(2026, 7, 15),
        startHour: 14,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
      );
      expect(window.start, DateTime.utc(2026, 7, 15, 11));
      expect(window.end, DateTime.utc(2026, 7, 15, 14));
    });

    test('rejects a local time in the 2026 DST spring-forward gap', () {
      expect(
        () => ScheduleTime.fromLocal(
          date: DateTime(2026, 3, 29),
          startHour: 0,
          startMinute: 30,
          endHour: 2,
          endMinute: 0,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('permits an overnight window and rejects zero duration', () {
      final overnight = ScheduleTime.fromLocal(
        date: DateTime(2026, 10, 30),
        startHour: 22,
        startMinute: 0,
        endHour: 2,
        endMinute: 0,
      );
      expect(overnight.end.isAfter(overnight.start), isTrue);
      expect(
        () => ScheduleTime.fromLocal(
          date: DateTime(2026, 10, 30),
          startHour: 14,
          startMinute: 0,
          endHour: 14,
          endMinute: 0,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('Order and public tracking models accept null and scheduled windows',
      () {
    final unscheduled = Order.fromJson(_orderJson());
    expect(unscheduled.scheduledWindowStart, isNull);
    expect(unscheduled.scheduledWindowEnd, isNull);
    expect(unscheduled.scheduleState, 'UNSCHEDULED');

    final scheduled = Order.fromJson(_orderJson(
      start: '2026-10-30T11:00:00.000Z',
      end: '2026-10-30T14:00:00.000Z',
      state: 'UPCOMING',
    ));
    expect(scheduled.scheduledWindowStart, DateTime.utc(2026, 10, 30, 11));
    expect(scheduled.scheduleState, 'UPCOMING');

    final publicOrder = PublicTrackingOrder.fromJson({
      ..._orderJson(start: null, end: null),
      'driver': 'Not assigned',
      'isExpress': false,
    });
    expect(publicOrder.scheduledWindowStart, isNull);
  });

  test(
      'create payload keeps schedule optional and sends scheduled values as UTC ISO',
      () {
    final base = buildCreateOrderPayload(
      orderId: 'GD-15',
      merchantUsername: 'shop-one',
      customerFirstName: 'Maya',
      customerPhone: '70123456',
      district: 'Baabda',
      city: 'Hazmieh',
      total: 25,
      deliveryCharge: 5,
    );
    expect(base.containsKey('scheduledWindowStart'), isFalse);

    final scheduled = buildCreateOrderPayload(
      orderId: 'GD-16',
      merchantUsername: 'shop-one',
      customerFirstName: 'Maya',
      customerPhone: '70123456',
      district: 'Baabda',
      city: 'Hazmieh',
      total: 25,
      deliveryCharge: 5,
      scheduledWindowStart: DateTime.utc(2026, 10, 30, 11),
      scheduledWindowEnd: DateTime.utc(2026, 10, 30, 14),
    );
    expect(scheduled['scheduledWindowStart'], '2026-10-30T11:00:00.000Z');
    expect(scheduled['scheduledWindowEnd'], '2026-10-30T14:00:00.000Z');
  });

  test('schedule board groups and dispatch models parse schedule metadata', () {
    final board = ScheduleBoardData.fromJson({
      'total': 1,
      'page': 1,
      'groups': {
        'TODAY': [
          {
            'id': 'GD-15',
            'status': 'NEW',
            'customerFirstName': 'Maya',
            'district': 'Baabda',
            'city': 'Hazmieh',
            'merchant': 'shop-one',
            'isExpress': true,
            'scheduledWindowStart': '2026-10-30T11:00:00.000Z',
            'scheduledWindowEnd': '2026-10-30T14:00:00.000Z',
            'scheduleState': 'UPCOMING',
          }
        ],
      },
    });
    expect(board.groups['TODAY']!.single.id, 'GD-15');
    expect(board.groups['TODAY']!.single.isExpress, isTrue);

    final dispatchOrder = DispatchOrder.fromJson({
      'id': 'GD-15',
      'scheduledWindowStart': '2026-10-30T11:00:00.000Z',
      'scheduledWindowEnd': '2026-10-30T14:00:00.000Z',
      'scheduleState': 'UPCOMING',
      'merchant': {'username': 'shop-one'},
    });
    expect(dispatchOrder.scheduleState, 'UPCOMING');

    final sequence = DriverSequenceItem.fromJson({
      'id': 'GD-15',
      'scheduledWindowStart': '2026-10-30T11:00:00.000Z',
      'scheduledWindowEnd': '2026-10-30T14:00:00.000Z',
      'scheduleState': 'UPCOMING',
    });
    expect(sequence.scheduledWindowStart, DateTime.utc(2026, 10, 30, 11));
  });

  testWidgets(
      'schedule picker toggles on and opens date and time pickers without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<ScheduleWindowPickerState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ScheduleWindowPicker(key: key, onChanged: (_) {}),
          ),
        ),
      ),
    ));
    expect(find.byKey(const Key('schedule_choose_date')), findsNothing);
    await tester.tap(find.byKey(const Key('schedule_delivery_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule_choose_date')), findsOneWidget);
    expect(key.currentState!.validate(), isNotNull);

    await tester.tap(find.byKey(const Key('schedule_choose_date')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('schedule_choose_start')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'admin can edit order schedule while Driver detail remains read-only',
      (tester) async {
    final order = Order.fromJson(_orderJson(
      start: '2026-10-30T11:00:00.000Z',
      end: '2026-10-30T14:00:00.000Z',
      state: 'UPCOMING',
    ));
    Widget view(bool canEdit) => MaterialApp(
          home: Scaffold(
            body: OrderScheduleCard(
                order: order, canEdit: canEdit, onEdit: () {}),
          ),
        );

    await tester.pumpWidget(view(true));
    expect(find.byKey(const Key('edit_order_schedule')), findsOneWidget);
    expect(find.byKey(const Key('order_schedule_window')), findsOneWidget);
    await tester.pumpWidget(view(false));
    expect(find.byKey(const Key('edit_order_schedule')), findsNothing);
  });
}
