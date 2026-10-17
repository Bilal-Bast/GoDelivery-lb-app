import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/live_location.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';
import '../../widgets/live_tracking.dart';

class AdminLiveTrackingScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loader;
  final Duration pollingInterval;

  const AdminLiveTrackingScreen({
    super.key,
    this.loader,
    this.pollingInterval = const Duration(seconds: 12),
  });

  @override
  State<AdminLiveTrackingScreen> createState() =>
      _AdminLiveTrackingScreenState();
}

class _AdminLiveTrackingScreenState extends State<AdminLiveTrackingScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  LiveDriversSnapshot? _snapshot;
  bool _loading = false;
  bool _initialLoad = true;
  bool _foreground = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  void _startPolling() {
    if (!_foreground) return;
    unawaited(_load());
    _timer?.cancel();
    _timer = Timer.periodic(widget.pollingInterval, (_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || _loading || !_foreground) return;
    _loading = true;
    try {
      final result = await (widget.loader ?? ApiService.getAdminLiveDrivers)();
      if (!mounted) return;
      final data = result['data'] is Map
          ? Map<String, dynamic>.from(result['data'] as Map)
          : result;
      if (result['success'] != true) {
        setState(() {
          _error = 'Live driver locations are temporarily unavailable.';
          _snapshot = null;
        });
      } else {
        final snapshot = LiveDriversSnapshot.fromJson(data);
        setState(() {
          _snapshot = snapshot;
          _error = null;
        });
        if (!snapshot.enabled) {
          _timer?.cancel();
          _timer = null;
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Live driver locations are temporarily unavailable.';
        _snapshot = null;
      });
    } finally {
      _loading = false;
      _initialLoad = false;
      if (mounted) setState(() {});
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
    final snapshot = _snapshot;
    final drivers = snapshot?.drivers ?? const <LiveDriverLocation>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Live drivers')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(context.pagePadding),
            children: [
              AppPageHeader(
                title: 'Live drivers',
                subtitle: 'Current locations for active deliveries only',
                actions: [
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_initialLoad)
                const AppLoadingState(
                    message: 'Checking live driver locations…')
              else if (_error != null)
                AppErrorState(message: _error!, onRetry: _load)
              else if (snapshot?.enabled != true)
                const AppSurfaceCard(
                  child: AppEmptyState(
                    title: 'Live tracking is disabled',
                    message:
                        'Enable the server setting only after confirming the backend uses a single process.',
                    icon: Icons.location_disabled_outlined,
                  ),
                )
              else if (drivers.isEmpty)
                const AppSurfaceCard(
                  child: AppEmptyState(
                    title: 'No drivers are sharing live location',
                    message:
                        'Locations appear while a driver shares from the app and has an active delivery.',
                    icon: Icons.location_searching_rounded,
                  ),
                )
              else ...[
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title:
                            '${drivers.length} active driver${drivers.length == 1 ? '' : 's'}',
                        subtitle:
                            'Only fresh points linked to picked-up orders are shown.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LiveTrackingMap(
                        height:
                            MediaQuery.sizeOf(context).width < 600 ? 250 : 360,
                        points: [
                          for (final driver in drivers)
                            LiveMapPoint(
                              id: driver.driverId,
                              label: driver.displayName.isEmpty
                                  ? driver.username
                                  : driver.displayName,
                              latitude: driver.latitude,
                              longitude: driver.longitude,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final driver in drivers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSectionHeader(
                            title: driver.displayName.isEmpty
                                ? driver.username
                                : driver.displayName,
                            subtitle:
                                '${driver.activeOrderIds.length} active picked-up order${driver.activeOrderIds.length == 1 ? '' : 's'} · GPS ±${driver.accuracy.round()} m',
                          ),
                          if (driver.updatedAt != null) ...[
                            const SizedBox(height: 6),
                            Text('Updated ${_formatTime(driver.updatedAt!)}'),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(value.toLocal()),
      );
}
