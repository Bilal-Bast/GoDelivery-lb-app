import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/dispatch_plan.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';

class AdminDispatchPlanningScreen extends StatefulWidget {
  const AdminDispatchPlanningScreen({super.key});

  @override
  State<AdminDispatchPlanningScreen> createState() =>
      _AdminDispatchPlanningScreenState();
}

class _AdminDispatchPlanningScreenState
    extends State<AdminDispatchPlanningScreen> {
  String _status = 'ALL';
  String _assignment = 'unassigned';
  String _scope = 'all';
  String? _express;
  int _page = 1;
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _merchant = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _district.dispose();
    _city.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Map<String, String> get _filters => {
        'status': _status,
        'assignment': _assignment,
        'scope': _scope,
        'page': '$_page',
        'limit': '50',
        if (_express != null) 'express': _express!,
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
        if (_merchant.text.trim().isNotEmpty)
          'merchantUsername': _merchant.text.trim(),
      };

  Future<void> _load() =>
      context.read<DispatchPlanningProvider>().load(filters: _filters);

  Future<void> _applyFilters() async {
    setState(() => _page = 1);
    await _load();
  }

  Future<void> _reviewAssignment(DispatchOrder order) async {
    final board = context.read<DispatchPlanningProvider>().board;
    if (board == null || board.drivers.isEmpty) return;
    final username = await showDialog<String>(
      context: context,
      builder: (context) => _AssignmentReviewDialog(
        order: order,
        drivers: board.drivers,
      ),
    );
    if (username == null || !mounted) return;
    final provider = context.read<DispatchPlanningProvider>();
    final saved = await provider.assign(order, username);
    if (!mounted) return;
    if (!saved) await provider.load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'Driver assignment saved.'
            : provider.assignmentError ?? 'Assignment was not saved.'),
        backgroundColor: saved ? AppColors.teal : AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DispatchPlanningProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.board == null) {
              return const AppLoadingState(message: 'Loading dispatch plan…');
            }
            if (provider.error != null && provider.board == null) {
              return AppErrorState(
                title: 'Dispatch planning unavailable',
                message: provider.error!,
                onRetry: _load,
              );
            }
            final board = provider.board;
            return RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(context.pagePadding),
                children: [
                  AppPageHeader(
                    title: 'Dispatch planning',
                    subtitle:
                        'Review server suggestions based on workload, Express priority, and existing area text.',
                    actions: [
                      OutlinedButton.icon(
                        key: const Key('dispatch_refresh'),
                        onPressed: provider.isLoading ? null : _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _filtersWidget(),
                  if (provider.error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _Notice(message: provider.error!, isError: true),
                  ],
                  if (board != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${board.totalOrders} order${board.totalOrders == 1 ? '' : 's'} · page ${board.page} of ${board.totalPages} · suggestions only; no distance or ETA',
                      key: const Key('dispatch_summary'),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppSectionHeader(
                      title: 'Driver workload',
                      subtitle:
                          'Fresh location sharing is informational and does not affect ranking.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (board.drivers.isEmpty)
                      const _Notice(
                        message:
                            'No DRIVER accounts are available for recommendations.',
                      )
                    else
                      AppResponsiveGrid(
                        minItemWidth: 235,
                        mainAxisExtent: 250,
                        children: [
                          for (final driver in board.drivers)
                            _DriverWorkloadCard(driver: driver),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    const AppSectionHeader(
                      title: 'Orders by area',
                      subtitle:
                          'Only WAREHOUSE and NEW orders are shown on the dispatch board.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (board.groups.isEmpty)
                      const AppSurfaceCard(
                        child: AppEmptyState(
                          title: 'No waiting orders',
                          message:
                              'No dispatchable orders match the selected filters.',
                          icon: Icons.inventory_2_outlined,
                        ),
                      )
                    else
                      for (final district in board.groups) ...[
                        _DistrictGroup(
                          district: district,
                          onReview: _reviewAssignment,
                          isAssigning: provider.isAssigning,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    const SizedBox(height: AppSpacing.md),
                    _Pagination(
                      page: board.page,
                      pages: board.totalPages,
                      hasPrevious: board.hasPrevious,
                      hasNext: board.hasNext,
                      onPrevious: () async {
                        setState(() => _page = (_page - 1).clamp(1, 1000));
                        await _load();
                      },
                      onNext: () async {
                        setState(() => _page++);
                        await _load();
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _filtersWidget() => AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _dropdown(
                    'Status',
                    _status,
                    const {
                      'ALL': 'Warehouse + New',
                      'WAREHOUSE': 'Warehouse',
                      'NEW': 'New',
                    },
                    (value) => setState(() => _status = value)),
                _dropdown(
                    'Assignment',
                    _assignment,
                    const {
                      'unassigned': 'Unassigned',
                      'assigned': 'Assigned',
                      'all': 'All',
                    },
                    (value) => setState(() => _assignment = value)),
                _dropdown(
                    'Created',
                    _scope,
                    const {
                      'all': 'All waiting',
                      'today': 'Today (Beirut)',
                    },
                    (value) => setState(() => _scope = value)),
                _dropdown(
                    'Express',
                    _express ?? '',
                    const {
                      '': 'All',
                      'true': 'Express',
                      'false': 'Standard',
                    },
                    (value) => setState(
                        () => _express = value.isEmpty ? null : value)),
                _searchField('District', _district),
                _searchField('City', _city),
                _searchField('Merchant', _merchant),
                FilledButton.icon(
                  key: const Key('dispatch_apply_filters'),
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) =>
      SizedBox(
        width: 174,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: [
            for (final entry in options.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      );

  Widget _searchField(String label, TextEditingController controller) =>
      SizedBox(
        width: 174,
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Any $label',
            isDense: true,
          ),
          onSubmitted: (_) => _applyFilters(),
        ),
      );
}

class _DriverWorkloadCard extends StatelessWidget {
  final DispatchDriver driver;

  const _DriverWorkloadCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final workload = driver.workload;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(driver.displayName, style: context.textStyles.titleMedium),
          Text('@${driver.username}', style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${workload.activeCount} active · ${workload.waitingCount} waiting · ${workload.pickedUpCount} picked up',
            style: context.textStyles.bodySmall,
          ),
          Text(
            '${workload.weightedUnits} workload units · ${workload.expressActiveCount} Express',
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                driver.isLive ? Icons.location_on : Icons.location_off,
                size: 16,
                color: driver.isLive ? AppColors.teal : AppColors.inkMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  driver.isLive
                      ? 'Fresh location sharing'
                      : 'No fresh location',
                  style: context.textStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistrictGroup extends StatelessWidget {
  final DispatchDistrictGroup district;
  final ValueChanged<DispatchOrder> onReview;
  final bool Function(String) isAssigning;

  const _DistrictGroup({
    required this.district,
    required this.onReview,
    required this.isAssigning,
  });

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(district.district, style: context.textStyles.titleLarge),
            for (final city in district.cities) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${city.city} · ${city.orderCount} orders · ${city.expressCount} Express',
                style: context.textStyles.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final order in city.orders) ...[
                _DispatchOrderCard(
                  order: order,
                  onReview: () => onReview(order),
                  isAssigning: isAssigning(order.id),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ],
        ),
      );
}

class _DispatchOrderCard extends StatelessWidget {
  final DispatchOrder order;
  final VoidCallback onReview;
  final bool isAssigning;

  const _DispatchOrderCard({
    required this.order,
    required this.onReview,
    required this.isAssigning,
  });

  @override
  Widget build(BuildContext context) {
    final recommended = order.recommendation?.recommendedDriver;
    return Container(
      key: Key('dispatch_order_${order.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: order.isExpress
            ? AppColors.amber.withValues(alpha: .07)
            : context.colors.surface,
        border: Border.all(color: context.colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('#${order.id}', style: context.textStyles.titleSmall),
              _StatusChip(label: order.status),
              if (order.isExpress)
                const _StatusChip(label: 'EXPRESS', express: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Merchant: ${order.merchantName}'),
          Text('${order.district} · ${order.city}'),
          Text(
              'Waiting since ${MaterialLocalizations.of(context).formatShortDate(order.createdAt.toLocal())}'),
          if (order.currentDriver != null)
            Text('Assigned to ${order.currentDriver!.displayName}'),
          if (recommended != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Suggested driver: ${recommended.displayName} · ${recommended.workload.activeCount} active',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final reason in order.recommendation!.reasons.take(3))
              Text('• $reason', style: context.textStyles.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: Key('dispatch_review_${order.id}'),
                onPressed: isAssigning ? null : onReview,
                icon: isAssigning
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rule_folder_outlined),
                label: const Text('Review assignment'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentReviewDialog extends StatefulWidget {
  final DispatchOrder order;
  final List<DispatchDriver> drivers;

  const _AssignmentReviewDialog({required this.order, required this.drivers});

  @override
  State<_AssignmentReviewDialog> createState() =>
      _AssignmentReviewDialogState();
}

class _AssignmentReviewDialogState extends State<_AssignmentReviewDialog> {
  late String _selectedUsername;

  @override
  void initState() {
    super.initState();
    _selectedUsername =
        widget.order.recommendation?.recommendedDriver?.username ??
            widget.drivers.first.username;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const Key('dispatch_assignment_review_dialog'),
        title: const Text('Review assignment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#${widget.order.id} · ${widget.order.status}'),
              Text('${widget.order.district} · ${widget.order.city}'),
              if (widget.order.isExpress)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Express priority'),
                ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('dispatch_driver_choice'),
                initialValue: _selectedUsername,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Driver'),
                items: [
                  for (final driver in widget.drivers)
                    DropdownMenuItem(
                      value: driver.username,
                      child: Text(
                        '${driver.displayName} · ${driver.workload.activeCount} active',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedUsername = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                  'Recommendation: ${widget.order.recommendation?.recommendedDriver?.displayName ?? 'none'}'),
              for (final reason
                  in widget.order.recommendation?.reasons ?? const <String>[])
                Text('• $reason', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Suggestions use workload and area text only. No distance or ETA is calculated.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('dispatch_cancel_assignment'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('dispatch_confirm_assignment'),
            onPressed: () => Navigator.of(context).pop(_selectedUsername),
            child: const Text('Confirm assignment'),
          ),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool express;

  const _StatusChip({required this.label, this.express = false});

  @override
  Widget build(BuildContext context) => Chip(
        visualDensity: VisualDensity.compact,
        label: Text(label),
        backgroundColor: express
            ? AppColors.amber.withValues(alpha: .2)
            : context.colors.surfaceContainerHighest,
        side: BorderSide.none,
      );
}

class _Notice extends StatelessWidget {
  final String message;
  final bool isError;

  const _Notice({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
        child: Text(
          message,
          style: TextStyle(color: isError ? AppColors.red : null),
        ),
      );
}

class _Pagination extends StatelessWidget {
  final int page;
  final int pages;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _Pagination({
    required this.page,
    required this.pages,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        children: [
          OutlinedButton(
            onPressed: hasPrevious ? onPrevious : null,
            child: const Text('Previous'),
          ),
          Text('Page $page of $pages'),
          OutlinedButton(
            onPressed: hasNext ? onNext : null,
            child: const Text('Next'),
          ),
        ],
      );
}
