import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_tokens.dart';
import '../services/driver_location_service.dart';
import 'app_components.dart';

class DriverLiveTrackingControl extends StatelessWidget {
  final bool hasActiveDelivery;

  const DriverLiveTrackingControl({
    super.key,
    required this.hasActiveDelivery,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverLiveTrackingProvider>(
      builder: (context, tracking, child) {
        final requested = tracking.isTrackingRequested;
        final busy =
            tracking.status == DriverTrackingStatus.requestingPermission;
        final canResume = requested &&
            tracking.status != DriverTrackingStatus.active &&
            tracking.status != DriverTrackingStatus.requestingPermission;
        final statusLabel = !tracking.isSupported
            ? 'Unavailable on this device'
            : switch (tracking.status) {
                DriverTrackingStatus.active => 'Live tracking active',
                DriverTrackingStatus.paused =>
                  'Paused while app is in background',
                DriverTrackingStatus.requestingPermission =>
                  'Checking location access',
                DriverTrackingStatus.permissionDenied => 'Permission denied',
                DriverTrackingStatus.permissionDeniedForever =>
                  'Permission blocked',
                DriverTrackingStatus.serviceDisabled =>
                  'Location services are off',
                DriverTrackingStatus.unsupported =>
                  'Unavailable on this device',
                DriverTrackingStatus.lowAccuracy => 'Waiting for accurate GPS',
                DriverTrackingStatus.connectionIssue => 'Connection issue',
                DriverTrackingStatus.stopped => 'Live tracking stopped',
                DriverTrackingStatus.idle => 'Off',
              };
        return AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Live delivery location',
                subtitle: tracking.message ??
                    'You choose when to share. Location is used only while delivering.',
              ),
              const SizedBox(height: AppSpacing.xs),
              Chip(
                label: Text(statusLabel),
                visualDensity: VisualDensity.compact,
              ),
              if (!hasActiveDelivery && !requested) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Start sharing after an order is picked up.',
                  style: context.textStyles.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (!requested)
                    FilledButton.icon(
                      key: const Key('driver_live_tracking_start'),
                      onPressed:
                          hasActiveDelivery && tracking.isSupported && !busy
                              ? tracking.start
                              : null,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Start live tracking'),
                    )
                  else ...[
                    if (canResume && hasActiveDelivery)
                      OutlinedButton.icon(
                        key: const Key('driver_live_tracking_resume'),
                        onPressed: busy ? null : tracking.resume,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Resume'),
                      ),
                    OutlinedButton.icon(
                      key: const Key('driver_live_tracking_stop'),
                      onPressed: busy ? null : tracking.stop,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop sharing'),
                    ),
                  ],
                  if (tracking.status ==
                      DriverTrackingStatus.permissionDeniedForever)
                    TextButton.icon(
                      key: const Key('driver_live_tracking_settings'),
                      onPressed: tracking.openPermissionSettings,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Open settings'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sharing pauses in the background. No route history is stored.',
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
