import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/app_notification.dart';
import 'package:godelivery_lb_app/models/user.dart';
import 'package:godelivery_lb_app/providers/providers.dart';
import 'package:godelivery_lb_app/services/notification_service.dart';

User user(String role) => User(
    id: '${role.toLowerCase()}1',
    username: role,
    role: role,
    firstName: '',
    lastName: '');

Map<String, dynamic> message(String type, String entityType, String id) => {
      'id': '$type:$id',
      'type': type,
      'entityType': entityType,
      'entityId': id,
      'title': 'Unsafe user title',
      'body': 'Secret user body'
    };

class FakePlatform implements NotificationPlatform {
  final foreground = StreamController<Map<String, dynamic>>.broadcast();
  final taps = StreamController<Map<String, dynamic>>.broadcast();
  NotificationPermissionState state = NotificationPermissionState.notRequested;
  @override
  bool get supported => true;
  @override
  Future<NotificationPermissionState> permission() async => state;
  @override
  Future<NotificationPermissionState> requestPermission() async =>
      state = NotificationPermissionState.denied;
  @override
  Future<bool> openSystemSettings() async => true;
  @override
  Stream<Map<String, dynamic>> get foregroundMessages => foreground.stream;
  @override
  Stream<Map<String, dynamic>> get notificationTaps => taps.stream;
  @override
  Future<Map<String, dynamic>?> initialMessage() async => null;
  Future<void> close() async {
    await foreground.close();
    await taps.close();
  }
}

Future<AuthProvider> signedIn(String role) async {
  final auth = AuthProvider(
    sessionExists: () async => true,
    sessionValidator: () async => true,
    userLoader: () async => user(role).toJson(),
    clearSession: () async {},
  );
  await auth.restoreSession();
  return auth;
}

void main() {
  test('payload validation discards unknown types and untrusted body', () {
    expect(AppNotification.parse(message('UNKNOWN', 'order', 'A1')), isNull);
    expect(AppNotification.parse(message('ORDER_ASSIGNED', 'payment', 'A1')),
        isNull);
    final item =
        AppNotification.parse(message('ORDER_ASSIGNED', 'order', 'A1'))!;
    expect(item.body, 'An order was assigned to you');
    expect(item.title, 'GoDelivery update');
  });

  test('tap routing derives only from role and existing protected routes', () {
    final admin =
        AppNotification.parse(message('ORDER_CREATED', 'order', 'A1'))!;
    final assigned =
        AppNotification.parse(message('ORDER_ASSIGNED', 'order', 'A1'))!;
    final delivered =
        AppNotification.parse(message('ORDER_DELIVERED', 'order', 'A1'))!;
    final payment = AppNotification.parse(
        message('MERCHANT_PAYMENT_CREATED', 'payment', 'p1'))!;
    expect(admin.routeFor(user('ADMIN')), '/home/orders/A1');
    expect(admin.routeFor(user('DRIVER')), isNull);
    expect(assigned.routeFor(user('DRIVER')), '/home/driver-orders');
    expect(delivered.routeFor(user('MERCHANT')), '/home/orders/A1');
    expect(payment.routeFor(user('MERCHANT')), '/home/merchant-payments');
    expect(payment.routeFor(user('DRIVER')), isNull);
  });

  test('unsupported permission is nonblocking and foreground is role safe',
      () async {
    final auth = await signedIn('DRIVER');
    final shown = <AppNotification>[];
    final service = NotificationService(
        auth: auth,
        present: shown.add,
        navigate: (_) {},
        loadRecent: () async => {
              'success': true,
              'data': {'items': []}
            });
    await service.initialize();
    await service.requestPermission();
    expect(service.permissionState, NotificationPermissionState.unsupported);
    service.receiveForeground(message('ORDER_ASSIGNED', 'order', 'A1'));
    service.receiveForeground(
        message('MERCHANT_PAYMENT_CREATED', 'payment', 'p1'));
    expect(shown.length, 1);
    service.dispose();
    auth.dispose();
  });

  test('denied permission does not block in-app feed or taps', () async {
    final auth = await signedIn('MERCHANT');
    final platform = FakePlatform();
    final shown = <AppNotification>[];
    final routes = <String>[];
    var calls = 0;
    final service = NotificationService(
        auth: auth,
        platform: platform,
        present: shown.add,
        navigate: routes.add,
        loadRecent: () async => {
              'success': true,
              'data': {
                'items': calls++ == 0
                    ? []
                    : [message('ORDER_DELIVERED', 'order', 'A1')]
              }
            });
    await service.initialize();
    await service.requestPermission();
    expect(service.permissionState, NotificationPermissionState.denied);
    await Future<void>.delayed(Duration.zero);
    await service.poll();
    expect(service.recent.length, 1);
    expect(shown.length, 1);
    service.handleTap(message('ORDER_DELIVERED', 'order', 'A1'));
    expect(routes, ['/home/orders/A1']);
    service.dispose();
    auth.dispose();
    await platform.close();
  });

  test('logout clears account activity and rejects later taps', () async {
    final auth = await signedIn('ADMIN');
    final routes = <String>[];
    final service = NotificationService(
        auth: auth,
        present: (_) {},
        navigate: routes.add,
        loadRecent: () async => {
              'success': true,
              'data': {
                'items': [message('ORDER_CREATED', 'order', 'A1')]
              }
            });
    await service.initialize();
    await service.poll();
    expect(service.recent, isNotEmpty);
    await auth.logout();
    expect(service.recent, isEmpty);
    service.handleTap(message('ORDER_CREATED', 'order', 'A1'));
    expect(routes, isEmpty);
    service.dispose();
    auth.dispose();
  });
}
