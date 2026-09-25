import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/public_tracking.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';
import '../../widgets/godelivery_logo.dart';

class TrackingScreen extends StatefulWidget {
  final String initialOrderId;
  const TrackingScreen({super.key, this.initialOrderId = ''});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final TextEditingController _id;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(text: widget.initialOrderId);
    if (widget.initialOrderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<TrackingProvider>().track(widget.initialOrderId),
      );
    }
  }

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const GoDeliveryLogo(height: 34),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AppContent(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppPageHeader(
                  title: 'Track your order',
                  subtitle:
                      'Enter the exact order ID supplied by the merchant.',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSurfaceCard(
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        key: const Key('tracking_order_id'),
                        controller: _id,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _track(),
                        decoration: const InputDecoration(
                          labelText: 'Order ID',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      key: const Key('tracking_submit'),
                      onPressed: tracking.isLoading ? null : _track,
                      child: const Text('Track'),
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.md),
                if (tracking.isLoading)
                  const AppLoadingState(message: 'Looking up your order…')
                else if (tracking.error != null)
                  AppErrorState(
                    message: tracking.error!,
                    onRetry: () async => _track(),
                  )
                else if (tracking.order != null)
                  _TrackingResult(order: tracking.order!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _track() {
    final id = _id.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order ID is required.')),
      );
      return;
    }
    context.read<TrackingProvider>().track(id);
  }
}

class _TrackingResult extends StatelessWidget {
  final PublicTrackingOrder order;
  const _TrackingResult({required this.order});

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child:
                    Text('#${order.id}', style: context.textStyles.titleLarge),
              ),
              OrderStatusBadge(status: order.status.code),
            ]),
            const Divider(height: AppSpacing.xl),
            AppInfoRow(label: 'Customer', value: order.customerName),
            AppInfoRow(label: 'Phone', value: order.phone),
            AppInfoRow(
              label: 'Destination',
              value: '${order.city}, ${order.district}',
            ),
            AppInfoRow(label: 'Order total', value: formatUsd(order.total)),
            AppInfoRow(label: 'Driver', value: order.driver),
            if (order.isExpress)
              const AppInfoRow(label: 'Service', value: 'Exchange / express'),
          ],
        ),
      );
}
