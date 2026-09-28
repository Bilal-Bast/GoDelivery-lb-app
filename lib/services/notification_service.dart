import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../providers/providers.dart';
import 'api_service.dart';

enum NotificationPermissionState {
  unsupported,
  notRequested,
  granted,
  denied,
  settingsRequired
}

abstract class NotificationPlatform {
  bool get supported;
  Future<NotificationPermissionState> permission();
  Future<NotificationPermissionState> requestPermission();
  Future<bool> openSystemSettings();
  Stream<Map<String, dynamic>> get foregroundMessages;
  Stream<Map<String, dynamic>> get notificationTaps;
  Future<Map<String, dynamic>?> initialMessage();
}

class DisabledNotificationPlatform implements NotificationPlatform {
  @override
  bool get supported => false;
  @override
  Future<NotificationPermissionState> permission() async =>
      NotificationPermissionState.unsupported;
  @override
  Future<NotificationPermissionState> requestPermission() async =>
      NotificationPermissionState.unsupported;
  @override
  Future<bool> openSystemSettings() async => false;
  @override
  Stream<Map<String, dynamic>> get foregroundMessages => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get notificationTaps => const Stream.empty();
  @override
  Future<Map<String, dynamic>?> initialMessage() async => null;
}

class NotificationService extends ChangeNotifier {
  final AuthProvider auth;
  final NotificationPlatform platform;
  final Future<Map<String, dynamic>> Function() loadRecent;
  final void Function(AppNotification) present;
  final void Function(String) navigate;
  NotificationPermissionState permissionState =
      NotificationPermissionState.unsupported;
  String? error;
  bool initialized = false;
  List<AppNotification> recent = const [];
  Set<String> _seen = {};
  bool _baselineLoaded = false;
  int _pollGeneration = 0;
  String? _accountId;
  StreamSubscription<Map<String, dynamic>>? _foregroundSubscription;
  StreamSubscription<Map<String, dynamic>>? _tapSubscription;
  Timer? _poller;
  AppNotification? _pendingTap;

  NotificationService(
      {required this.auth,
      required this.present,
      required this.navigate,
      NotificationPlatform? platform,
      Future<Map<String, dynamic>> Function()? loadRecent})
      : platform = platform ?? DisabledNotificationPlatform(),
        loadRecent = loadRecent ?? ApiService.getRecentNotifications {
    auth.addListener(_onAuthChanged);
  }

  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;
    try {
      permissionState = await platform.permission();
      _foregroundSubscription =
          platform.foregroundMessages.listen(receiveForeground);
      _tapSubscription = platform.notificationTaps.listen(handleTap);
      final initial = await platform.initialMessage();
      if (initial != null) handleTap(initial);
      _onAuthChanged();
    } catch (_) {
      error = 'Notification integration is unavailable';
      permissionState = NotificationPermissionState.unsupported;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    if (!platform.supported) return;
    try {
      permissionState = await platform.requestPermission();
      error = null;
    } catch (_) {
      error = 'Unable to request notification permission';
    }
    notifyListeners();
  }

  Future<bool> openSystemSettings() => platform.openSystemSettings();

  void _onAuthChanged() {
    final id = auth.isLoggedIn ? auth.currentUser?.id : null;
    if (id == _accountId) return;
    final pending = _accountId == null ? _pendingTap : null;
    _accountId = id;
    _poller?.cancel();
    _poller = id == null
        ? null
        : Timer.periodic(const Duration(seconds: 60), (_) => poll());
    _seen = {};
    _baselineLoaded = false;
    _pollGeneration++;
    recent = const [];
    _pendingTap = null;
    notifyListeners();
    if (id != null && initialized) {
      unawaited(poll(presentNew: false));
      if (pending != null) open(pending);
    }
  }

  Future<void> poll({bool presentNew = true}) async {
    final account = _accountId;
    if (account == null) return;
    final generation = ++_pollGeneration;
    try {
      final response = await loadRecent();
      if (account != _accountId || generation != _pollGeneration) return;
      if (response['success'] != true || response['data'] is! Map) return;
      final items = (response['data']['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AppNotification.parse(Map<String, dynamic>.from(item)))
          .whereType<AppNotification>()
          .where((item) => item.routeFor(auth.currentUser) != null)
          .toList();
      if (presentNew && _baselineLoaded) {
        for (final item in items.reversed) {
          if (!_seen.contains(item.id)) present(item);
        }
      }
      _seen = items.map((item) => item.id).toSet();
      _baselineLoaded = true;
      recent = items;
      error = null;
      notifyListeners();
    } catch (_) {
      if (account == _accountId && generation == _pollGeneration) {
        error = 'Recent activity is unavailable';
        notifyListeners();
      }
    }
  }

  void receiveForeground(Map<String, dynamic> data) {
    final item = AppNotification.parse(data);
    if (item != null && item.routeFor(auth.currentUser) != null) present(item);
  }

  void handleTap(Map<String, dynamic> data) {
    final item = AppNotification.parse(data);
    if (item == null) return;
    if (!auth.isLoggedIn) {
      _pendingTap = item;
      return;
    }
    open(item);
  }

  void open(AppNotification item) {
    final route = item.routeFor(auth.currentUser);
    if (route != null) navigate(route);
  }

  bool simulateForDebug(AppNotification item) {
    if (!kDebugMode || item.routeFor(auth.currentUser) == null) return false;
    present(item);
    return true;
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    _foregroundSubscription?.cancel();
    _tapSubscription?.cancel();
    _poller?.cancel();
    super.dispose();
  }
}
