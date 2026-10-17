import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/live_location.dart';
import '../models/order_status.dart';
import '../services/api_service.dart';
import 'app_components.dart';

const _liveMapTileUrl = String.fromEnvironment(
  'LIVE_MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);

class LiveMapPoint {
  final String id;
  final String label;
  final double latitude;
  final double longitude;

  const LiveMapPoint({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class LiveTrackingMap extends StatelessWidget {
  final List<LiveMapPoint> points;
  final double height;

  const LiveTrackingMap({
    super.key,
    required this.points,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final first = points.first;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(first.latitude, first.longitude),
            initialZoom: points.length == 1 ? 15 : 12,
            initialCameraFit: points.length > 1
                ? CameraFit.coordinates(
                    coordinates: points
                        .map((point) => LatLng(point.latitude, point.longitude))
                        .toList(growable: false),
                    padding: const EdgeInsets.all(36),
                    maxZoom: 15,
                    minZoom: 6,
                  )
                : null,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: _liveMapTileUrl,
              userAgentPackageName: 'com.godelivery_lb_app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                for (final point in points)
                  Marker(
                    key: ValueKey('live-location-${point.id}'),
                    point: LatLng(point.latitude, point.longitude),
                    width: 54,
                    height: 64,
                    child: Tooltip(
                      message: point.label,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF0B7B70),
                        size: 42,
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LiveOrderLocationPanel extends StatefulWidget {
  final String orderId;
  final OrderStatusValue status;
  final bool merchant;
  final Future<Map<String, dynamic>> Function(String orderId)? loader;
  final Duration pollingInterval;

  const LiveOrderLocationPanel({
    super.key,
    required this.orderId,
    required this.status,
    this.merchant = false,
    this.loader,
    this.pollingInterval = const Duration(seconds: 12),
  });

  @override
  State<LiveOrderLocationPanel> createState() => _LiveOrderLocationPanelState();
}

class _LiveOrderLocationPanelState extends State<LiveOrderLocationPanel>
    with WidgetsBindingObserver {
  Timer? _timer;
  LiveOrderLocation? _location;
  bool _loading = false;
  bool _hasLoaded = false;
  bool _foreground = true;
  bool _deliveryEnded = false;
  bool _serverDisabled = false;

  bool get _isActive => widget.status == OrderStatusValue.pickedUp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void didUpdateWidget(covariant LiveOrderLocationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.status != widget.status) {
      _location = null;
      _hasLoaded = false;
      _deliveryEnded = false;
      _serverDisabled = false;
      _timer?.cancel();
      _startPolling();
    }
  }

  void _startPolling() {
    if (!_isActive || !_foreground) return;
    unawaited(_load());
    _timer?.cancel();
    _timer = Timer.periodic(widget.pollingInterval, (_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || !_isActive || _loading || !_foreground) return;
    _loading = true;
    try {
      final loader = widget.loader ??
          (widget.merchant
              ? ApiService.getMerchantOrderLiveLocation
              : ApiService.getPublicOrderLiveLocation);
      final result = await loader(widget.orderId);
      if (!mounted) return;
      final data = result['data'] is Map
          ? Map<String, dynamic>.from(result['data'] as Map)
          : result;
      if (result['success'] != true) {
        setState(() {
          _location = null;
          _hasLoaded = true;
        });
        return;
      }
      final location = LiveOrderLocation.fromJson(data);
      setState(() {
        _location = location;
        _deliveryEnded = !location.deliveryActive;
        _serverDisabled = !location.available;
        _hasLoaded = true;
      });
      if (_deliveryEnded || _serverDisabled) {
        _timer?.cancel();
        _timer = null;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _location = null;
        _hasLoaded = true;
      });
    } finally {
      _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _startPolling();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.merchant ? 'Live delivery' : 'Live delivery progress';
    if (widget.status == OrderStatusValue.delivered) {
      return AppSurfaceCard(
        child: AppSectionHeader(
          title: title,
          subtitle: 'Delivery completed. Live location sharing has ended.',
        ),
      );
    }
    if (widget.status == OrderStatusValue.cancelled ||
        widget.status == OrderStatusValue.paid ||
        widget.status == OrderStatusValue.collected) {
      return AppSurfaceCard(
        child: AppSectionHeader(
          title: title,
          subtitle: 'Live tracking is no longer available for this order.',
        ),
      );
    }
    if (_deliveryEnded) {
      return AppSurfaceCard(
        child: AppSectionHeader(
          title: title,
          subtitle: 'Live tracking has ended for this order.',
        ),
      );
    }
    if (!_isActive) {
      return AppSurfaceCard(
        child: AppSectionHeader(
          title: title,
          subtitle:
              'Driver location becomes available when the order is out for delivery.',
        ),
      );
    }

    final location = _location;
    final live = location != null &&
        location.isLive &&
        location.latitude != null &&
        location.longitude != null;
    final updatedAt = location?.updatedAt;
    final subtitle = live
        ? 'Driver is on the way · Updated ${_formatTime(updatedAt)}'
        : _serverDisabled || location?.available == false
            ? 'Driver location is temporarily unavailable.'
            : location?.isStale == true
                ? 'Driver location is temporarily stale. Waiting for a fresh update.'
                : _hasLoaded
                    ? 'Driver location is temporarily unavailable.'
                    : 'Checking for a live driver location…';
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: title,
            subtitle: subtitle,
          ),
          if (live) ...[
            const SizedBox(height: 12),
            LiveTrackingMap(
              height: MediaQuery.sizeOf(context).width < 600 ? 220 : 300,
              points: [
                LiveMapPoint(
                  id: widget.orderId,
                  label: 'Delivery driver',
                  latitude: location.latitude!,
                  longitude: location.longitude!,
                ),
              ],
            ),
            if (location.accuracy != null) ...[
              const SizedBox(height: 8),
              Text('GPS accuracy ±${location.accuracy!.round()} m'),
            ],
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return 'just now';
    return DateFormat('h:mm a').format(value.toLocal());
  }
}
