import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../models/communication_status.dart';
import '../services/api_service.dart';
import 'app_components.dart';

class CommunicationStatusCard extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() loadStatus;

  const CommunicationStatusCard({
    super.key,
    this.loadStatus = ApiService.getCommunicationStatus,
  });

  @override
  State<CommunicationStatusCard> createState() =>
      _CommunicationStatusCardState();
}

class _CommunicationStatusCardState extends State<CommunicationStatusCard> {
  late Future<Map<String, dynamic>> _status;

  @override
  void initState() {
    super.initState();
    _status = widget.loadStatus();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _status,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppSurfaceCard(
              child: LinearProgressIndicator(),
            );
          }
          final response = snapshot.data;
          final data = response?['data'];
          if (response?['success'] != true || data is! Map) {
            return AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    title: 'Transactional communications',
                    subtitle: 'Provider configuration status',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(response?['error']?.toString() ??
                      'Communication status is unavailable.'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _status = widget.loadStatus();
                      }),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          }
          final status = CommunicationStatus.fromJson(
            Map<String, dynamic>.from(data),
          );
          return AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(
                  title: 'Transactional communications',
                  subtitle: 'Provider: ${status.provider}',
                ),
                const SizedBox(height: AppSpacing.xs),
                _StatusLine(label: 'WhatsApp', value: status.whatsapp),
                _StatusLine(label: 'SMS', value: status.sms),
                if (status.customerAutomation)
                  const _StatusLine(
                    label: 'Customer automation',
                    value: 'Enabled',
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status.dryRun
                      ? 'Dry run only. No external message is sent.'
                      : 'Configuration only; provider delivery health is not checked.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      );
}

class _StatusLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatusLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      );
}
