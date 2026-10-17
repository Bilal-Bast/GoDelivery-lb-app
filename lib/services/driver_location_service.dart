import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

enum DriverLocationPermission { granted, denied, permanentlyDenied }

enum DriverTrackingStatus {
  idle,
  requestingPermission,
  active,
  paused,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unsupported,
  lowAccuracy,
  connectionIssue,
  stopped,
}

class DriverLocationFix {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? heading;
  final double? speed;
  final DateTime capturedAt;

  const DriverLocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.heading,
    this.speed,
    required this.capturedAt,
  });
}

abstract interface class DriverLocationSource {
  bool get isSupported;
  Future<bool> isServiceEnabled();
  Future<DriverLocationPermission> checkPermission();
  Future<DriverLocationPermission> requestPermission();
  Future<bool> openAppSettings();
  Stream<DriverLocationFix> watchPosition();
}

class GeolocatorDriverLocationSource implements DriverLocationSource {
  @override
  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<DriverLocationPermission> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  @override
  Future<DriverLocationPermission> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Stream<DriverLocationFix> watchPosition() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).map((position) => DriverLocationFix(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            heading: position.heading,
            speed: position.speed,
            capturedAt: position.timestamp.toUtc(),
          ));

  DriverLocationPermission _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always =>
          DriverLocationPermission.granted,
        LocationPermission.deniedForever =>
          DriverLocationPermission.permanentlyDenied,
        _ => DriverLocationPermission.denied,
      };
}

double distanceBetweenMeters(
  double latitudeA,
  double longitudeA,
  double latitudeB,
  double longitudeB,
) {
  const earthRadiusMeters = 6371000.0;
  final latA = latitudeA * math.pi / 180;
  final latB = latitudeB * math.pi / 180;
  final deltaLat = (latitudeB - latitudeA) * math.pi / 180;
  final deltaLng = (longitudeB - longitudeA) * math.pi / 180;
  final a = math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(latA) * math.cos(latB) * math.pow(math.sin(deltaLng / 2), 2);
  return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class DriverLiveTrackingProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  final DriverLocationSource _source;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) _publish;
  final Future<Map<String, dynamic>> Function() _stopRemote;
  final DateTime Function() _clock;
  final Duration minimumPublishInterval;
  final Duration refreshPublishInterval;
  final double minimumMovementMeters;

  StreamSubscription<DriverLocationFix>? _subscription;
  Future<Map<String, dynamic>>? _pendingPublish;
  DriverLocationFix? _lastPublished;
  DateTime? _lastPublishedAt;
  DriverTrackingStatus _status = DriverTrackingStatus.idle;
  bool _trackingRequested = false;
  bool _inForeground = true;
  bool _remoteMayHaveLocation = false;
  bool _publishing = false;
  String? _message;

  DriverLiveTrackingProvider({
    DriverLocationSource? source,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>)? publish,
    Future<Map<String, dynamic>> Function()? stopRemote,
    DateTime Function()? clock,
    this.minimumPublishInterval = const Duration(seconds: 5),
    this.refreshPublishInterval = const Duration(seconds: 10),
    this.minimumMovementMeters = 25,
  })  : _source = source ?? GeolocatorDriverLocationSource(),
        _publish = publish ?? ApiService.publishDriverLocation,
        _stopRemote = stopRemote ?? ApiService.stopDriverLocation,
        _clock = clock ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
  }

  DriverTrackingStatus get status => _status;
  String? get message => _message;
  bool get isTrackingRequested => _trackingRequested;
  bool get isActive => _status == DriverTrackingStatus.active;
  bool get isSupported => _source.isSupported;

  Future<bool> start() async {
    if (_trackingRequested) return isActive;
    if (!_source.isSupported) {
      _setState(DriverTrackingStatus.unsupported,
          'Live tracking is supported on Android, iOS, and secure web only.');
      return false;
    }
    _trackingRequested = true;
    _setState(DriverTrackingStatus.requestingPermission,
        'Share your location while delivering so operations and the customer can follow progress.');
    try {
      if (!await _source.isServiceEnabled()) {
        _trackingRequested = false;
        _setState(DriverTrackingStatus.serviceDisabled,
            'Turn on location services to share your live location.');
        return false;
      }
      var permission = await _source.checkPermission();
      if (permission == DriverLocationPermission.denied) {
        permission = await _source.requestPermission();
      }
      if (permission != DriverLocationPermission.granted) {
        _trackingRequested = false;
        if (permission == DriverLocationPermission.permanentlyDenied) {
          _setState(DriverTrackingStatus.permissionDeniedForever,
              'Location permission is blocked. Allow it in app settings to share while delivering.');
        } else {
          _setState(DriverTrackingStatus.permissionDenied,
              'Location permission was denied.');
        }
        return false;
      }
      return await _startForegroundStream();
    } catch (_) {
      _trackingRequested = false;
      _setState(DriverTrackingStatus.unsupported,
          'Unable to access location on this device.');
      return false;
    }
  }

  Future<bool> openPermissionSettings() => _source.openAppSettings();

  Future<bool> resume() async {
    if (!_trackingRequested) return start();
    if (!_source.isSupported) {
      _setState(DriverTrackingStatus.unsupported,
          'Live tracking is supported on Android, iOS, and secure web only.');
      return false;
    }
    _inForeground = true;
    _setState(
        DriverTrackingStatus.requestingPermission, 'Checking location access…');
    try {
      if (!await _source.isServiceEnabled()) {
        _setState(DriverTrackingStatus.serviceDisabled,
            'Turn on location services to resume live tracking.');
        return false;
      }
      var permission = await _source.checkPermission();
      if (permission == DriverLocationPermission.denied) {
        permission = await _source.requestPermission();
      }
      if (permission != DriverLocationPermission.granted) {
        _setState(
          permission == DriverLocationPermission.permanentlyDenied
              ? DriverTrackingStatus.permissionDeniedForever
              : DriverTrackingStatus.permissionDenied,
          'Location permission is unavailable. Live tracking is paused.',
        );
        return false;
      }
      return await _startForegroundStream();
    } catch (_) {
      _setState(DriverTrackingStatus.connectionIssue,
          'Unable to resume live tracking.');
      return false;
    }
  }

  Future<bool> _startForegroundStream() async {
    if (!_trackingRequested || !_inForeground) return false;
    if (!await _source.isServiceEnabled()) {
      _setState(DriverTrackingStatus.serviceDisabled,
          'Location services are off. Live tracking is paused.');
      return false;
    }
    final permission = await _source.checkPermission();
    if (permission != DriverLocationPermission.granted) {
      _setState(
        permission == DriverLocationPermission.permanentlyDenied
            ? DriverTrackingStatus.permissionDeniedForever
            : DriverTrackingStatus.permissionDenied,
        'Location permission is no longer available. Live tracking is paused.',
      );
      return false;
    }
    await _subscription?.cancel();
    _subscription = _source.watchPosition().listen(
          (fix) => unawaited(_handleFix(fix)),
          onError: (_) => _setState(
            DriverTrackingStatus.connectionIssue,
            'Unable to read the current location. Live tracking is paused.',
          ),
        );
    _setState(DriverTrackingStatus.active, 'Live tracking active');
    return true;
  }

  Future<void> _handleFix(DriverLocationFix fix) async {
    if (!_trackingRequested || !_inForeground || _publishing) return;
    if (!fix.latitude.isFinite ||
        !fix.longitude.isFinite ||
        fix.latitude < -90 ||
        fix.latitude > 90 ||
        fix.longitude < -180 ||
        fix.longitude > 180 ||
        !fix.accuracy.isFinite ||
        fix.accuracy < 0 ||
        fix.accuracy > 100) {
      _setState(DriverTrackingStatus.lowAccuracy,
          'Waiting for a more accurate GPS reading.');
      return;
    }
    final now = _clock().toUtc();
    final capturedAt = fix.capturedAt.toUtc();
    if (now.difference(capturedAt) > const Duration(minutes: 2) ||
        capturedAt.difference(now) > const Duration(seconds: 30)) {
      return;
    }
    final previous = _lastPublished;
    final lastAt = _lastPublishedAt;
    if (previous != null && lastAt != null) {
      final elapsed = now.difference(lastAt);
      final distance = distanceBetweenMeters(
        previous.latitude,
        previous.longitude,
        fix.latitude,
        fix.longitude,
      );
      final shouldRefresh = elapsed >= refreshPublishInterval;
      final movedEnough = elapsed >= minimumPublishInterval &&
          distance >= minimumMovementMeters;
      if (!shouldRefresh && !movedEnough) return;
    }

    _publishing = true;
    _lastPublished = fix;
    _lastPublishedAt = now;
    _remoteMayHaveLocation = true;
    Future<Map<String, dynamic>>? pending;
    try {
      pending = _publish({
        'latitude': fix.latitude,
        'longitude': fix.longitude,
        'accuracy': fix.accuracy,
        if (fix.heading != null && fix.heading!.isFinite)
          'heading': fix.heading,
        if (fix.speed != null && fix.speed!.isFinite && fix.speed! >= 0)
          'speed': fix.speed,
        'capturedAt': capturedAt.toIso8601String(),
      });
      _pendingPublish = pending;
      final result = await pending;
      if (!_trackingRequested || !_inForeground) {
        await _clearRemoteLocation();
        return;
      }
      if (result['success'] == true) {
        _setState(DriverTrackingStatus.active, 'Live tracking active');
      } else if ((result['statusCode'] as num?)?.toInt() == 409) {
        await stop();
        _setState(DriverTrackingStatus.stopped,
            'Live tracking stopped because there is no active delivery.');
      } else {
        _setState(DriverTrackingStatus.connectionIssue,
            'Unable to send the latest location. Retrying with a future GPS update.');
      }
    } catch (_) {
      if (!_trackingRequested || !_inForeground) {
        await _clearRemoteLocation();
        return;
      }
      _setState(DriverTrackingStatus.connectionIssue,
          'Unable to send the latest location. Retrying with a future GPS update.');
    } finally {
      if (pending != null && identical(_pendingPublish, pending)) {
        _pendingPublish = null;
      }
      _publishing = false;
    }
  }

  Future<void> stop() async {
    _trackingRequested = false;
    await _subscription?.cancel();
    _subscription = null;
    _lastPublished = null;
    _lastPublishedAt = null;
    final pending = _pendingPublish;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    await _clearRemoteLocation();
    _setState(DriverTrackingStatus.stopped, 'Live tracking stopped');
  }

  Future<void> stopForLogout() async {
    if (_trackingRequested || _subscription != null || _remoteMayHaveLocation) {
      await stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _inForeground = true;
      if (_trackingRequested) unawaited(_resumeTracking());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _inForeground = false;
      if (_trackingRequested) unawaited(_pauseTracking());
    }
  }

  Future<void> _pauseTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _lastPublished = null;
    _lastPublishedAt = null;
    final pending = _pendingPublish;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    await _clearRemoteLocation();
    if (_trackingRequested) {
      _setState(DriverTrackingStatus.paused,
          'Live tracking paused while the app is in the background.');
    }
  }

  Future<void> _resumeTracking() async {
    if (!_trackingRequested || !_inForeground) return;
    try {
      await _startForegroundStream();
    } catch (_) {
      _setState(DriverTrackingStatus.connectionIssue,
          'Unable to resume live tracking.');
    }
  }

  Future<void> _clearRemoteLocation() async {
    if (!_remoteMayHaveLocation) return;
    _remoteMayHaveLocation = false;
    try {
      await _stopRemote();
    } catch (_) {
      // Server-side TTL bounds any point that could not be cleared here.
    }
  }

  void _setState(DriverTrackingStatus status, String? message) {
    _status = status;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
