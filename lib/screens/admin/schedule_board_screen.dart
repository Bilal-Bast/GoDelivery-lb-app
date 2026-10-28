import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/time/schedule_time.dart';
import '../../models/schedule_board.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';

class ScheduleBoardScreen extends StatefulWidget {
  const ScheduleBoardScreen({super.key});

  @override
  State<ScheduleBoardScreen> createState() => _ScheduleBoardScreenState();
}

class _ScheduleBoardScreenState extends State<ScheduleBoardScreen> {
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _driver = TextEditingController();
  final _merchant = TextEditingController();
  ScheduleBoardData? _board;
  String? _error;
  String _status = '';
  String _express = '';
  int _page = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _district.dispose();
    _city.dispose();
    _driver.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Map<String, String> get _filters => {
        'page': '$_page',
        'limit': '50',
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
        if (_driver.text.trim().isNotEmpty) 'driver': _driver.text.trim(),
        if (_merchant.text.trim().isNotEmpty) 'merchant': _merchant.text.trim(),
        if (_status.isNotEmpty) 'status': _status,
        if (_express.isNotEmpty) 'express': _express,
      };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getScheduleBoard(filters: _filters);
    if (!mounted) return;
    if (result['success'] == true && result['data'] is Map) {
      setState(() => _board = ScheduleBoardData.fromJson(
            Map<String, dynamic>.from(result['data'] as Map),
          ));
    } else {
      setState(() => _error =
          result['error']?.toString() ?? 'Schedule board unavailable.');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showFilters() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, refresh) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppSectionHeader(
                    title: 'Schedule filters',
                    subtitle: 'Filters apply to this admin board.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                      controller: _district,
                      decoration: const InputDecoration(labelText: 'District')),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'City')),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                      controller: _driver,
                      decoration: const InputDecoration(
                          labelText: 'Driver username (or unassigned)')),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                      controller: _merchant,
                      decoration: const InputDecoration(
                          labelText: 'Merchant username')),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Active orders')),
                      DropdownMenuItem(
                          value: 'WAREHOUSE', child: Text('Warehouse')),
                      DropdownMenuItem(value: 'NEW', child: Text('New')),
                      DropdownMenuItem(
                          value: 'Picked_up', child: Text('Picked up')),
                    ],
                    onChanged: (value) => refresh(() => _status = value ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _express,
                    decoration: const InputDecoration(labelText: 'Express'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All orders')),
                      DropdownMenuItem(
                          value: 'true', child: Text('Express only')),
                      DropdownMenuItem(
                          value: 'false', child: Text('Standard only')),
                    ],
                    onChanged: (value) => refresh(() => _express = value ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    TextButton(
                      onPressed: () {
                        _district.clear();
                        _city.clear();
                        _driver.clear();
                        _merchant.clear();
                        refresh(() {
                          _status = '';
                          _express = '';
                        });
                      },
                      child: const Text('Clear filters'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Apply'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() => _page = 1);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery schedule'),
        actions: [
          IconButton(
              tooltip: 'Schedule filters',
              onPressed: _showFilters,
              icon: const Icon(Icons.tune_rounded)),
          IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.all(context.pagePadding),
            children: [
              const AppPageHeader(
                title: 'Delivery schedule',
                subtitle:
                    'Delivery commitments in Lebanon local time. Windows are not ETAs.',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (board != null)
                Text(
                    '${board.total} orders · ${board.timeZone} · page ${board.page} of ${board.totalPages}',
                    style: context.textStyles.bodySmall),
              if (_loading && board == null) const LinearProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppErrorState(message: _error!, onRetry: _load),
              ],
              if (board != null) ...[
                const SizedBox(height: AppSpacing.md),
                for (final group in const [
                  ('OVERDUE', 'Overdue'),
                  ('TODAY', 'Today'),
                  ('TOMORROW', 'Tomorrow'),
                  ('UPCOMING', 'Upcoming'),
                  ('UNSCHEDULED', 'Unscheduled'),
                  ('COMPLETED', 'Completed'),
                  ('CANCELLED', 'Cancelled'),
                ])
                  if ((board.groups[group.$1] ?? []).isNotEmpty) ...[
                    AppSectionHeader(
                        title:
                            '${group.$2} · ${board.groups[group.$1]!.length}'),
                    const SizedBox(height: AppSpacing.xs),
                    LayoutBuilder(builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 960
                          ? 3
                          : constraints.maxWidth >= 620
                              ? 2
                              : 1;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final order in board.groups[group.$1]!)
                            SizedBox(
                              width: (constraints.maxWidth -
                                      (columns - 1) * AppSpacing.sm) /
                                  columns,
                              child: _ScheduleOrderCard(order: order),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                  ],
                if (board.total == 0)
                  const AppEmptyState(
                      title: 'No scheduled orders',
                      message: 'Nothing matches these filters.',
                      icon: Icons.event_available_outlined),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  OutlinedButton.icon(
                    onPressed: board.hasPrevious && !_loading
                        ? () {
                            setState(() => _page--);
                            _load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('${board.page} / ${board.totalPages}')),
                  OutlinedButton.icon(
                    onPressed: board.hasNext && !_loading
                        ? () {
                            setState(() => _page++);
                            _load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleOrderCard extends StatelessWidget {
  final ScheduleBoardOrder order;
  const _ScheduleOrderCard({required this.order});

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
        key: Key('schedule_board_order_${order.id}'),
        onTap: () =>
            context.push('/home/orders/${Uri.encodeComponent(order.id)}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('#${order.id}', style: context.textStyles.titleSmall),
                  Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(order.status)),
                  if (order.isExpress)
                    const Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('Express')),
                ]),
            const SizedBox(height: AppSpacing.xs),
            Text(order.customerName.isEmpty
                ? 'Customer not listed'
                : order.customerName),
            Text('${order.district}, ${order.city}',
                style: context.textStyles.bodySmall),
            Text(
                'Merchant: ${order.merchant} · Driver: ${order.driver ?? 'Unassigned'}',
                style: context.textStyles.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              order.scheduledWindowStart != null &&
                      order.scheduledWindowEnd != null
                  ? ScheduleTime.formatWindow(
                      order.scheduledWindowStart, order.scheduledWindowEnd)
                  : 'No scheduled delivery',
              style: context.textStyles.titleSmall,
            ),
            Text(ScheduleTime.stateLabel(order.scheduleState),
                style: context.textStyles.bodySmall),
          ],
        ),
      );
}
