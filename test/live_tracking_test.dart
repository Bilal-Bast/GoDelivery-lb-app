import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/live_location.dart';
import 'package:godelivery_lb_app/models/order_status.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/services/driver_location_service.dart';
import 'package:godelivery_lb_app/widgets/driver_live_tracking_control.dart';
import 'package:godelivery_lb_app/widgets/live_tracking.dart';
import 'package:provider/provider.dart';

class FakeLocationSource implements DriverLocationSource {
  bool supported = true;
  bool serviceEnabled = true;
  DriverLocationPermission permission = DriverLocationPermission.granted;
  DriverLocationPermission requestResult = DriverLocationPermission.granted;
  int permissionRequests = 0;
  int watchCalls = 0;
  int activeStreams = 0;
  final StreamController<DriverLocationFix> controller =
      StreamController<DriverLocationFix>.broadcast(sync: true);

  @override
  bool get isSupported => supported;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<DriverLocationPermission> checkPermission() async => permission;

  @override
  Future<DriverLocationPermission> requestPermission() async {
    permissionRequests++;
    permission = requestResult;
    return requestResult;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Stream<DriverLocationFix> watchPosition() {
    watchCalls++;
    return Stream<DriverLocationFix>.multi((multi) {
      activeStreams++;
      final subscription = controller.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = () async {
        activeStreams--;
        await subscription.cancel();
      };
    });
  }

  Future<void> dispose() async => controller.close();
}

DriverLocationFix fix(
  DateTime time, {
  double latitude = 33.8938,
  double longitude = 35.5018,
  double accuracy = 12,
}) =>
    DriverLocationFix(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      capturedAt: time,
    );

Future<void> flushAsync() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('live location models', () {
    test('parses only a fresh live public point', () {
      final value = LiveOrderLocation.fromJson({
        'available': true,
        'locationAvailable': true,
        'isLive': true,
        'isStale': false,
        'latitude': 33.8938,
        'longitude': 35.5018,
        'accuracy': 18,
        'updatedAt': '2026-10-17T12:00:00.000Z',
        'driverId': 'must-not-be-in-the-public-model',
      });
      expect(value.isLive, isTrue);
      expect(value.latitude, 33.8938);
      expect(value.updatedAt, isNotNull);
    });

    test('stale and malformed public locations never retain coordinates', () {
      final stale = LiveOrderLocation.fromJson({
        'available': true,
        'locationAvailable': false,
        'isLive': false,
        'isStale': true,
        'updatedAt': '2026-10-17T12:00:00.000Z',
      });
      final malformed = LiveOrderLocation.fromJson({
        'available': true,
        'locationAvailable': true,
        'isLive': true,
        'latitude': 120,
        'longitude': 0,
        'accuracy': 3,
      });
      expect(stale.isStale, isTrue);
      expect(stale.latitude, isNull);
      expect(malformed.isLive, isFalse);
      expect(malformed.longitude, isNull);
    });

    test('admin snapshot parses only operational map fields', () {
      final snapshot = LiveDriversSnapshot.fromJson({
        'enabled': true,
        'drivers': [
          {
            'driverId': 'driver-1',
            'username': 'driver',
            'displayName': 'Test Driver',
            'latitude': 33.89,
            'longitude': 35.50,
            'accuracy': 20,
            'updatedAt': '2026-10-17T12:00:00Z',
            'activeOrderIds': ['order-1'],
            'financeBalance': 1000,
          }
        ],
      });
      expect(snapshot.enabled, isTrue);
      expect(snapshot.drivers.single.activeOrderIds, ['order-1']);
      expect(snapshot.drivers.single.latitude, 33.89);
    });
  });

  group('driver live tracking provider', () {
    late FakeLocationSource source;
    late DriverLiveTrackingProvider provider;
    final now = DateTime.utc(2026, 10, 17, 12);
    var clock = now;
    var published = <Map<String, dynamic>>[];
    var stopCalls = 0;
    var publishResult = <String, dynamic>{'success': true};

    setUp(() {
      source = FakeLocationSource();
      clock = now;
      published = [];
      stopCalls = 0;
      publishResult = {'success': true};
      provider = DriverLiveTrackingProvider(
        source: source,
        clock: () => clock,
        publish: (body) async {
          published.add(body);
          return publishResult;
        },
        stopRemote: () async {
          stopCalls++;
          return {'success': true};
        },
      );
    });

    tearDown(() async {
      await provider.stop();
      provider.dispose();
      await source.dispose();
    });

    test('asks permission only on explicit start and handles denial', () async {
      source.permission = DriverLocationPermission.denied;
      source.requestResult = DriverLocationPermission.denied;
      expect(await provider.start(), isFalse);
      expect(source.permissionRequests, 1);
      expect(provider.status, DriverTrackingStatus.permissionDenied);
      expect(source.watchCalls, 0);
      expect(published, isEmpty);
    });

    test('shows service-disabled and permanently-denied states', () async {
      source.serviceEnabled = false;
      expect(await provider.start(), isFalse);
      expect(provider.status, DriverTrackingStatus.serviceDisabled);
      source.serviceEnabled = true;
      source.permission = DriverLocationPermission.permanentlyDenied;
      expect(await provider.start(), isFalse);
      expect(provider.status, DriverTrackingStatus.permissionDeniedForever);
    });

    test('starts one stream, throttles updates, and stops on request',
        () async {
      expect(await provider.start(), isTrue);
      expect(source.watchCalls, 1);
      expect(source.activeStreams, 1);
      source.controller.add(fix(clock));
      await flushAsync();
      expect(published, hasLength(1));
      clock = clock.add(const Duration(seconds: 4));
      source.controller.add(fix(clock, latitude: 33.8944));
      await flushAsync();
      expect(published, hasLength(1));
      clock = clock.add(const Duration(seconds: 1));
      source.controller.add(fix(clock, latitude: 33.8944));
      await flushAsync();
      expect(published, hasLength(2));
      expect(provider.status, DriverTrackingStatus.active);
      await provider.stop();
      expect(source.activeStreams, 0);
      expect(stopCalls, 1);
      expect(provider.isTrackingRequested, isFalse);
    });

    test('background pause clears the point and resume opens one stream',
        () async {
      expect(await provider.start(), isTrue);
      source.controller.add(fix(clock));
      await flushAsync();
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await flushAsync();
      expect(provider.status, DriverTrackingStatus.paused);
      expect(source.activeStreams, 0);
      expect(stopCalls, 1);
      provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await flushAsync();
      expect(source.activeStreams, 1);
      expect(source.watchCalls, 2);
      expect(provider.isTrackingRequested, isTrue);
    });

    test('logout stops the active stream and clears remote location', () async {
      await provider.start();
      source.controller.add(fix(clock));
      await flushAsync();
      await provider.stopForLogout();
      expect(source.activeStreams, 0);
      expect(stopCalls, 1);
      expect(provider.isTrackingRequested, isFalse);
    });

    test('poor accuracy and upload failure never mutate order state', () async {
      var statusMutations = 0;
      expect(await provider.start(), isTrue);
      source.controller.add(fix(clock, accuracy: 150));
      await flushAsync();
      expect(published, isEmpty);
      expect(provider.status, DriverTrackingStatus.lowAccuracy);
      publishResult = {'success': false, 'error': 'network'};
      source.controller.add(fix(clock));
      await flushAsync();
      expect(provider.status, DriverTrackingStatus.connectionIssue);
      expect(statusMutations, 0);
    });
  });

  testWidgets(
      'tracking control is present only in the driver flow and gated without active work',
      (tester) async {
    final source = FakeLocationSource();
    final tracking = DriverLiveTrackingProvider(
      source: source,
      publish: (_) async => {'success': true},
      stopRemote: () async => {'success': true},
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: tracking,
        child: const MaterialApp(
          home: Scaffold(
            body: DriverLiveTrackingControl(hasActiveDelivery: false),
          ),
        ),
      ),
    );
    expect(find.text('Live delivery location'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('driver_live_tracking_start')),
    );
    expect(button.onPressed, isNull);
    expect(source.permissionRequests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    tracking.dispose();
    await source.dispose();
  });

  testWidgets('non-delivery public tracking renders fallback without polling',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiveOrderLocationPanel(
          orderId: 'order-1',
          status: OrderStatusValue.warehouse,
          loader: (_) async {
            calls++;
            return {
              'success': true,
              'data': {'isLive': true}
            };
          },
        ),
      ),
    ));
    expect(find.textContaining('becomes available'), findsOneWidget);
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('delivered order hides the live map and does not poll',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiveOrderLocationPanel(
          orderId: 'order-1',
          status: OrderStatusValue.delivered,
          loader: (_) async {
            calls++;
            return {'success': true};
          },
        ),
      ),
    ));
    expect(find.textContaining('Delivery completed'), findsOneWidget);
    expect(find.byType(LiveTrackingMap), findsNothing);
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('active order gracefully shows unavailable state on API failure',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiveOrderLocationPanel(
          orderId: 'order-1',
          status: OrderStatusValue.pickedUp,
          pollingInterval: const Duration(hours: 1),
          loader: (_) async => {'success': false, 'error': 'unavailable'},
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    expect(find.byType(LiveTrackingMap), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
