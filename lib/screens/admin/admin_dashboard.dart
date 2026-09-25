import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/admin_models.dart';
import '../../models/order.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<OrderProvider>().fetchOrders(),
      context.read<AdminProvider>().loadDashboard(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<OrderProvider, AdminProvider>(
          builder: (context, orders, admin, child) {
            final isFirstLoad = orders.isLoading && orders.orders.isEmpty;
            if (isFirstLoad) {
              return const AppLoadingState(
                message: 'Loading operations overview…',
              );
            }

            if (orders.error != null && orders.orders.isEmpty) {
              return AppErrorState(
                title: 'Dashboard unavailable',
                message: orders.error!,
                onRetry: _refresh,
              );
            }

            final data = DashboardSnapshot.from(
              orders: orders.orders,
              analytics: admin.analytics,
            );
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AppContent(
                      child: DashboardContent(
                        data: data,
                        orders: orders.orders,
                        warning: admin.error,
                        refreshing: orders.isLoading || admin.isLoading,
                        onRefresh: _refresh,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final DashboardSnapshot data;
  final List<Order> orders;
  final String? warning;
  final bool refreshing;
  final Future<void> Function() onRefresh;

  const DashboardContent({
    super.key,
    required this.data,
    required this.orders,
    required this.warning,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final name = user?.firstName.trim().isNotEmpty == true
        ? user!.firstName.trim()
        : 'Admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Good day, $name',
          subtitle: 'Here is the latest view of your delivery network.',
          eyebrow: const OperationalBadge(),
          actions: [
            OutlinedButton.icon(
              key: const Key('dashboard_refresh_button'),
              onPressed: refreshing ? null : () => onRefresh(),
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              key: const Key('dashboard_create_order_button'),
              onPressed: () => context.push('/home/create-order'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New order'),
            ),
          ],
        ),
        if (warning != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DashboardWarning(message: warning!),
        ],
        const SizedBox(height: AppSpacing.lg),
        DashboardPrimaryMetrics(data: data),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Order flow',
          subtitle: 'Current volume across every delivery stage',
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardStatusGrid(data: data),
        const SizedBox(height: AppSpacing.xl),
        DashboardInsights(data: data),
        const SizedBox(height: AppSpacing.xl),
        DashboardRecentOrders(orders: orders),
      ],
    );
  }
}

class OperationalBadge extends StatelessWidget {
  const OperationalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Operations live',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: AppColors.teal),
            SizedBox(width: 7),
            Text(
              'OPERATIONS LIVE',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardWarning extends StatelessWidget {
  final String message;

  const DashboardWarning({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.amber.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.amber),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Some live analytics could not be loaded. Order data is still shown. $message',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPrimaryMetrics extends StatelessWidget {
  final DashboardSnapshot data;

  const DashboardPrimaryMetrics({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AppResponsiveGrid(
      minItemWidth: 220,
      mainAxisExtent: 158,
      children: [
        AppMetricCard(
          label: 'Total orders',
          value: NumberFormat.decimalPattern().format(data.totalOrders),
          hint: '${data.ordersToday} today',
          icon: Icons.inventory_2_outlined,
          color: AppColors.blue,
        ),
        AppMetricCard(
          label: 'Revenue',
          value: formatUsd(data.revenue),
          hint: 'Delivered value',
          icon: Icons.payments_outlined,
          color: AppColors.teal,
        ),
        AppMetricCard(
          label: 'Active drivers',
          value: '${data.activeDrivers}',
          hint: 'On the network',
          icon: Icons.local_shipping_outlined,
          color: AppColors.violet,
        ),
        AppMetricCard(
          label: 'Delivery rate',
          value: '${data.deliveryRate.toStringAsFixed(1)}%',
          hint: '${data.successfulOrders} completed',
          icon: Icons.trending_up_rounded,
          color: AppColors.brand,
        ),
      ],
    );
  }
}

class DashboardStatusGrid extends StatelessWidget {
  final DashboardSnapshot data;

  const DashboardStatusGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      StatusSummary('Warehouse', data.warehouse, 'WAREHOUSE'),
      StatusSummary('New', data.newOrders, 'NEW'),
      StatusSummary('Picked up', data.pickedUp, 'PICKED_UP'),
      StatusSummary('Delivered', data.delivered, 'DELIVERED'),
      StatusSummary('Cancelled', data.cancelled, 'CANCELLED'),
      StatusSummary('Paid', data.paid, 'PAID'),
      StatusSummary('Collected', data.collected, 'COLLECTED'),
    ];
    return AppResponsiveGrid(
      minItemWidth: 150,
      mainAxisExtent: 116,
      maxColumns: 7,
      spacing: AppSpacing.sm,
      children: [
        for (final status in statuses) StatusSummaryCard(summary: status),
      ],
    );
  }
}

class StatusSummary {
  final String label;
  final int count;
  final String status;

  const StatusSummary(this.label, this.count, this.status);
}

class StatusSummaryCard extends StatelessWidget {
  final StatusSummary summary;

  const StatusSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final style = OrderStatusStyle.from(summary.status);
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(style.icon, size: 20, color: style.color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${summary.count}', style: context.textStyles.titleLarge),
                const SizedBox(height: 2),
                Text(
                  summary.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardInsights extends StatelessWidget {
  final DashboardSnapshot data;

  const DashboardInsights({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final flow = StatusDistributionPanel(data: data);
        const actions = DashboardQuickActions();
        if (!wide) {
          return Column(
            children: [
              flow,
              const SizedBox(height: AppSpacing.md),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: flow),
            const SizedBox(width: AppSpacing.md),
            const Expanded(flex: 2, child: actions),
          ],
        );
      },
    );
  }
}

class StatusDistributionPanel extends StatelessWidget {
  final DashboardSnapshot data;

  const StatusDistributionPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = [
      StatusSummary('Warehouse', data.warehouse, 'WAREHOUSE'),
      StatusSummary('New', data.newOrders, 'NEW'),
      StatusSummary('Picked up', data.pickedUp, 'PICKED_UP'),
      StatusSummary('Delivered', data.delivered, 'DELIVERED'),
    ];
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Operational distribution',
            subtitle: 'Share of orders in the active delivery pipeline',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in values) ...[
            StatusDistributionRow(
              summary: item,
              total: data.totalOrders,
            ),
            if (item != values.last) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class StatusDistributionRow extends StatelessWidget {
  final StatusSummary summary;
  final int total;

  const StatusDistributionRow({
    super.key,
    required this.summary,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final style = OrderStatusStyle.from(summary.status);
    final progress = total == 0 ? 0.0 : summary.count / total;
    return Column(
      children: [
        Row(
          children: [
            Icon(style.icon, size: 18, color: style.color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
                child:
                    Text(summary.label, style: context.textStyles.labelLarge)),
            Text('${summary.count}', style: context.textStyles.titleSmall),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 44,
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.end,
                style: context.textStyles.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 7,
            color: style.color,
            backgroundColor: style.color.withValues(alpha: .1),
          ),
        ),
      ],
    );
  }
}

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Quick actions',
            subtitle: 'Common control-center tasks',
          ),
          const SizedBox(height: AppSpacing.md),
          QuickActionTile(
            key: const Key('quick_action_create_order'),
            icon: Icons.add_box_outlined,
            title: 'Create order',
            subtitle: 'Register a new delivery',
            color: AppColors.brand,
            onTap: () => context.push('/home/create-order'),
          ),
          const SizedBox(height: AppSpacing.xs),
          QuickActionTile(
            icon: Icons.search_rounded,
            title: 'Find an order',
            subtitle: 'Search by customer, phone or ID',
            color: AppColors.blue,
            onTap: () => context.go('/home/orders'),
          ),
          const SizedBox(height: AppSpacing.xs),
          QuickActionTile(
            icon: Icons.local_shipping_outlined,
            title: 'Manage drivers',
            subtitle: 'Review the driver roster',
            color: AppColors.violet,
            onTap: () => context.go('/home/admin/drivers'),
          ),
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardRecentOrders extends StatelessWidget {
  final List<Order> orders;

  const DashboardRecentOrders({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final recent = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visible = recent.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Recent orders',
          subtitle: 'Latest activity across the network',
          trailing: TextButton(
            onPressed: () => context.go('/home/orders'),
            child: const Text('View all'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          AppSurfaceCard(
            child: AppEmptyState(
              title: 'No orders yet',
              message:
                  'New delivery orders will appear here as they are created.',
              action: FilledButton.icon(
                onPressed: () => context.push('/home/create-order'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create first order'),
              ),
            ),
          )
        else
          AppSurfaceCard(
            padding: EdgeInsets.zero,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Column(
                  children: [
                    if (wide) const RecentOrdersHeader(),
                    for (var index = 0; index < visible.length; index++) ...[
                      RecentOrderRow(order: visible[index], wide: wide),
                      if (index != visible.length - 1) const Divider(),
                    ],
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class RecentOrdersHeader extends StatelessWidget {
  const RecentOrdersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.labelMedium;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: context.colors.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('ORDER', style: style)),
          Expanded(flex: 2, child: Text('CUSTOMER', style: style)),
          Expanded(flex: 2, child: Text('LOCATION', style: style)),
          Expanded(
              child: Text('AMOUNT', style: style, textAlign: TextAlign.end)),
          const SizedBox(width: 128),
        ],
      ),
    );
  }
}

class RecentOrderRow extends StatelessWidget {
  final Order order;
  final bool wide;

  const RecentOrderRow({
    super.key,
    required this.order,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/home/orders/${order.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: wide
            ? RecentOrderDesktopRow(order: order)
            : RecentOrderMobileRow(order: order),
      ),
    );
  }
}

class RecentOrderDesktopRow extends StatelessWidget {
  final Order order;

  const RecentOrderDesktopRow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#${shortIdentifier(order.id)}',
                  style: context.textStyles.titleSmall),
              Text(
                DateFormat('MMM d, HH:mm').format(order.createdAt.toLocal()),
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            order.customerName.isEmpty
                ? 'Unknown customer'
                : order.customerName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            [order.city, order.district]
                .where((value) => value.isNotEmpty)
                .join(', '),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            formatUsd(order.total),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleSmall,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
            width: 104,
            child: OrderStatusBadge(status: order.status, showIcon: false)),
        const Icon(Icons.chevron_right_rounded, size: 20),
      ],
    );
  }
}

class RecentOrderMobileRow extends StatelessWidget {
  final Order order;

  const RecentOrderMobileRow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '#${shortIdentifier(order.id)}',
                style: context.textStyles.titleSmall,
              ),
            ),
            OrderStatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          order.customerName.isEmpty ? 'Unknown customer' : order.customerName,
          style: context.textStyles.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${order.city}, ${order.district}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('MMM d, HH:mm').format(order.createdAt.toLocal()),
                style: context.textStyles.bodySmall,
              ),
            ),
            Flexible(
              child: Text(
                formatUsd(order.total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: context.textStyles.titleSmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardSnapshot {
  final int totalOrders;
  final double revenue;
  final int ordersToday;
  final int activeDrivers;
  final int warehouse;
  final int newOrders;
  final int pickedUp;
  final int delivered;
  final int cancelled;
  final int paid;
  final int collected;

  const DashboardSnapshot({
    required this.totalOrders,
    required this.revenue,
    required this.ordersToday,
    required this.activeDrivers,
    required this.warehouse,
    required this.newOrders,
    required this.pickedUp,
    required this.delivered,
    required this.cancelled,
    required this.paid,
    required this.collected,
  });

  int get successfulOrders => delivered + paid + collected;

  double get deliveryRate =>
      totalOrders == 0 ? 0 : successfulOrders / totalOrders * 100;

  factory DashboardSnapshot.from({
    required List<Order> orders,
    required AnalyticsOverview? analytics,
  }) {
    int count(String status) => orders
        .where((order) =>
            order.status.toUpperCase().replaceAll(' ', '_') == status)
        .length;
    int analyticsCount(int index, String fallbackStatus) {
      final values = analytics?.statusCounts;
      return values != null && index < values.length
          ? values[index]
          : count(fallbackStatus);
    }

    final cancelledOrders = orders.where((order) {
      final status = order.status.toUpperCase();
      return status == 'CANCELLED' || status == 'CANCELED';
    }).length;
    final fallbackRevenue = orders
        .where((order) => !order.isCanceled)
        .fold<double>(0, (sum, order) => sum + order.merchantAmount);

    return DashboardSnapshot(
      totalOrders: analytics?.totalOrders ?? orders.length,
      revenue: analytics?.totalRevenue ?? fallbackRevenue,
      ordersToday: analytics?.ordersToday ?? 0,
      activeDrivers: analytics?.activeDrivers ?? 0,
      warehouse: analyticsCount(0, 'WAREHOUSE'),
      newOrders: analyticsCount(1, 'NEW'),
      pickedUp: analyticsCount(2, 'PICKED_UP'),
      delivered: analyticsCount(3, 'DELIVERED'),
      cancelled:
          analytics?.statusCounts != null && analytics!.statusCounts.length > 4
              ? analytics.statusCounts[4]
              : cancelledOrders,
      paid: analyticsCount(5, 'PAID'),
      collected: analyticsCount(6, 'COLLECTED'),
    );
  }
}
