import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/order.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';

const orderStatusFilters = [
  'ALL',
  'WAREHOUSE',
  'NEW',
  'PICKED_UP',
  'DELIVERED',
  'PAID',
  'CANCELLED',
  'COLLECTED',
];

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadOrders() => context.read<OrderProvider>().fetchOrders();

  List<Order> _filtered(List<Order> orders) {
    return orders.where((order) {
      final statusMatches = _selectedStatus == 'ALL' ||
          order.status.toUpperCase().replaceAll(' ', '_') == _selectedStatus;
      if (!statusMatches) return false;
      if (_searchQuery.isEmpty) return true;
      return [
        order.id,
        order.customerName,
        order.customerPhone,
        order.merchantId,
        order.city,
        order.district,
      ].any((value) => value.toLowerCase().contains(_searchQuery));
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.orders.isEmpty) {
              return const AppLoadingState(message: 'Loading orders…');
            }
            if (provider.error != null && provider.orders.isEmpty) {
              return AppErrorState(
                title: 'Orders unavailable',
                message: provider.error!,
                onRetry: _loadOrders,
              );
            }
            final filtered = _filtered(provider.orders);
            return LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 960;
                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    key: const PageStorageKey('orders_list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(context.pagePadding),
                    itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
                    separatorBuilder: (context, index) => SizedBox(
                      height: index == 0 ? AppSpacing.md : AppSpacing.sm,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return OrdersHeader(
                          controller: _searchController,
                          selectedStatus: _selectedStatus,
                          totalCount: provider.orders.length,
                          visibleCount: filtered.length,
                          loading: provider.isLoading,
                          onStatusChanged: (status) {
                            setState(() => _selectedStatus = status);
                          },
                          onRefresh: _loadOrders,
                        );
                      }
                      if (filtered.isEmpty) {
                        return AppSurfaceCard(
                          child: AppEmptyState(
                            title: 'No matching orders',
                            message: _searchQuery.isNotEmpty
                                ? 'Try a different order ID, customer, phone, merchant or location.'
                                : 'There are no orders in the selected status.',
                            icon: Icons.search_off_rounded,
                            action: TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _selectedStatus = 'ALL');
                              },
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Clear filters'),
                            ),
                          ),
                        );
                      }
                      final order = filtered[index - 1];
                      return desktop
                          ? DesktopOrderRow(order: order)
                          : MobileOrderCard(order: order);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class OrdersHeader extends StatelessWidget {
  final TextEditingController controller;
  final String selectedStatus;
  final int totalCount;
  final int visibleCount;
  final bool loading;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function() onRefresh;

  const OrdersHeader({
    super.key,
    required this.controller,
    required this.selectedStatus,
    required this.totalCount,
    required this.visibleCount,
    required this.loading,
    required this.onStatusChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final canCreate =
        context.watch<AuthProvider>().currentUser?.isDriver != true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Orders',
          subtitle: '$visibleCount of $totalCount orders shown',
          actions: [
            OutlinedButton.icon(
              key: const Key('orders_refresh_button'),
              onPressed: loading ? null : () => onRefresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
            if (canCreate)
              FilledButton.icon(
                key: const Key('orders_create_button'),
                onPressed: () => context.push('/home/create-order'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New order'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('orders_search_field'),
                controller: controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText:
                      'Search order ID, customer, phone, merchant or location',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: controller.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0;
                        index < orderStatusFilters.length;
                        index++) ...[
                      FilterChip(
                        key: Key(
                            'orders_filter_${orderStatusFilters[index].toLowerCase()}'),
                        label: Text(
                          orderStatusFilters[index] == 'ALL'
                              ? 'All orders'
                              : OrderStatusStyle.from(orderStatusFilters[index])
                                  .label,
                        ),
                        selected: selectedStatus == orderStatusFilters[index],
                        onSelected: (_) =>
                            onStatusChanged(orderStatusFilters[index]),
                        showCheckmark: false,
                        avatar: orderStatusFilters[index] == 'ALL'
                            ? const Icon(Icons.all_inbox_outlined, size: 17)
                            : Icon(
                                OrderStatusStyle.from(orderStatusFilters[index])
                                    .icon,
                                size: 17,
                                color:
                                    selectedStatus == orderStatusFilters[index]
                                        ? AppColors.brandStrong
                                        : null,
                              ),
                      ),
                      if (index != orderStatusFilters.length - 1)
                        const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        const OrdersColumnLabels(),
      ],
    );
  }
}

class OrdersColumnLabels extends StatelessWidget {
  const OrdersColumnLabels({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960) return const SizedBox.shrink();
        final style = context.textStyles.labelMedium;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('ORDER', style: style)),
              Expanded(flex: 2, child: Text('CUSTOMER', style: style)),
              Expanded(flex: 2, child: Text('LOCATION', style: style)),
              Expanded(
                  child:
                      Text('PAYMENT', style: style, textAlign: TextAlign.end)),
              const SizedBox(width: 16),
              SizedBox(width: 112, child: Text('STATUS', style: style)),
              const SizedBox(width: 24),
            ],
          ),
        );
      },
    );
  }
}

class DesktopOrderRow extends StatelessWidget {
  final Order order;

  const DesktopOrderRow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/home/orders/${order.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OrderIdentity(order: order),
            ),
            Expanded(
              flex: 2,
              child: CustomerIdentity(order: order),
            ),
            Expanded(
              flex: 2,
              child: Text(
                locationLabel(order),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyMedium,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatLbp(order.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall),
                  Text('Fee ${formatLbp(order.deliveryCharge)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
                width: 112,
                child: OrderStatusBadge(status: order.status, showIcon: false)),
            const Icon(Icons.chevron_right_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}

class MobileOrderCard extends StatelessWidget {
  final Order order;

  const MobileOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/home/orders/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: OrderIdentity(order: order)),
              const SizedBox(width: AppSpacing.sm),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CustomerIdentity(order: order),
          const SizedBox(height: AppSpacing.sm),
          IconTextLine(
              icon: Icons.location_on_outlined, text: locationLabel(order)),
          const SizedBox(height: AppSpacing.xs),
          IconTextLine(
            icon: Icons.storefront_outlined,
            text: order.merchantId.isEmpty
                ? 'Merchant unavailable'
                : order.merchantId,
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              if (order.isExpress) ...[
                const ExpressBadge(),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  formatLbp(order.total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: context.textStyles.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderIdentity extends StatelessWidget {
  final Order order;

  const OrderIdentity({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '#${shortIdentifier(order.id, length: 12)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleSmall,
              ),
            ),
            if (order.isExpress) ...[
              const SizedBox(width: 6),
              const Icon(Icons.bolt_rounded, size: 17, color: AppColors.amber),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          DateFormat('MMM d, yyyy · HH:mm').format(order.createdAt.toLocal()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.bodySmall,
        ),
      ],
    );
  }
}

class CustomerIdentity extends StatelessWidget {
  final Order order;

  const CustomerIdentity({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.customerName.isEmpty ? 'Unknown customer' : order.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.titleSmall,
        ),
        const SizedBox(height: 3),
        Text(
          order.customerPhone.isEmpty ? 'No phone number' : order.customerPhone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.bodySmall,
        ),
      ],
    );
  }
}

class IconTextLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const IconTextLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class ExpressBadge extends StatelessWidget {
  const ExpressBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 15, color: AppColors.amber),
          SizedBox(width: 4),
          Text(
            'EXPRESS',
            style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String locationLabel(Order order) {
  final values =
      [order.city, order.district].where((value) => value.trim().isNotEmpty);
  return values.isEmpty ? 'Location unavailable' : values.join(', ');
}

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderProvider>().fetchOrder(widget.orderId),
    );
  }

  Future<void> _updateStatus(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDeliveredDialog(),
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<OrderProvider>().updateOrderStatus(
          order.id,
          'DELIVERED',
        );
    if (!mounted) return;
    final provider = context.read<OrderProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Order marked as delivered'
              : provider.error ?? 'Failed to update order',
        ),
        backgroundColor: success ? AppColors.teal : AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading &&
            provider.selectedOrder?.id != widget.orderId) {
          return const Scaffold(
              body: AppLoadingState(message: 'Loading order details…'));
        }
        final order = provider.selectedOrder;
        if (order == null || order.id != widget.orderId) {
          return Scaffold(
            body: AppErrorState(
              title: 'Order not found',
              message: provider.error ?? 'This order could not be loaded.',
              onRetry: () => provider.fetchOrder(widget.orderId),
            ),
          );
        }
        final compact =
            MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
        return Scaffold(
          bottomNavigationBar: compact && order.isPending
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: FilledButton.icon(
                      key: const Key('order_detail_update_status_button'),
                      onPressed: provider.isLoading
                          ? null
                          : () => _updateStatus(order),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Mark as delivered'),
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: SingleChildScrollView(
              child: AppContent(
                maxWidth: 1120,
                padding: EdgeInsets.fromLTRB(
                  context.pagePadding,
                  context.pagePadding,
                  context.pagePadding,
                  compact && order.isPending
                      ? AppSpacing.xxl
                      : context.pagePadding,
                ),
                child: OrderDetailContent(
                  order: order,
                  showHeaderAction: !compact && order.isPending,
                  updating: provider.isLoading,
                  onUpdate: () => _updateStatus(order),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrderDetailContent extends StatelessWidget {
  final Order order;
  final bool showHeaderAction;
  final bool updating;
  final VoidCallback onUpdate;

  const OrderDetailContent({
    super.key,
    required this.order,
    required this.showHeaderAction,
    required this.updating,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Order #${shortIdentifier(order.id, length: 14)}',
          subtitle:
              'Created ${DateFormat('MMM d, yyyy · HH:mm').format(order.createdAt.toLocal())}',
          eyebrow: Align(
              alignment: Alignment.centerLeft,
              child: OrderStatusBadge(status: order.status)),
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
            if (showHeaderAction)
              FilledButton.icon(
                key: const Key('order_detail_update_status_button'),
                onPressed: updating ? null : onUpdate,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Mark as delivered'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OrderStatusHero(order: order),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final customer = CustomerDetailCard(order: order);
            final details = OrderMetaCard(order: order);
            if (!wide) {
              return Column(
                children: [
                  customer,
                  const SizedBox(height: AppSpacing.md),
                  details,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: customer),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: details),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        PricingDetailCard(order: order),
      ],
    );
  }
}

class OrderStatusHero extends StatelessWidget {
  final Order order;

  const OrderStatusHero({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusStyle.from(order.status);
    return AppSurfaceCard(
      color: status.color.withValues(alpha: .055),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(status.icon, color: status.color, size: 27),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current status', style: context.textStyles.bodySmall),
                const SizedBox(height: 2),
                Text(status.label,
                    style: context.textStyles.titleLarge
                        ?.copyWith(color: status.color)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Last updated', style: context.textStyles.bodySmall),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, HH:mm')
                    .format(order.statusUpdatedAt.toLocal()),
                style: context.textStyles.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerDetailCard extends StatelessWidget {
  final Order order;

  const CustomerDetailCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
              title: 'Customer', subtitle: 'Contact and delivery location'),
          const SizedBox(height: AppSpacing.sm),
          AppInfoRow(
              label: 'Name',
              value: order.customerName.isEmpty
                  ? 'Unknown customer'
                  : order.customerName,
              icon: Icons.person_outline_rounded),
          const Divider(),
          AppInfoRow(
              label: 'Phone',
              value: order.customerPhone.isEmpty
                  ? 'Not provided'
                  : order.customerPhone,
              icon: Icons.phone_outlined),
          const Divider(),
          AppInfoRow(
              label: 'District',
              value: order.district,
              icon: Icons.map_outlined),
          const Divider(),
          AppInfoRow(
              label: 'City',
              value: order.city,
              icon: Icons.location_on_outlined),
        ],
      ),
    );
  }
}

class OrderMetaCard extends StatelessWidget {
  final Order order;

  const OrderMetaCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
              title: 'Delivery', subtitle: 'Order ownership and service level'),
          const SizedBox(height: AppSpacing.sm),
          AppInfoRow(
              label: 'Order ID', value: order.id, icon: Icons.tag_rounded),
          const Divider(),
          AppInfoRow(
              label: 'Merchant',
              value: order.merchantId,
              icon: Icons.storefront_outlined),
          const Divider(),
          AppInfoRow(
              label: 'Driver',
              value: order.driverId ?? 'Not assigned',
              icon: Icons.local_shipping_outlined),
          const Divider(),
          AppInfoRow(
              label: 'Service',
              value: order.isExpress ? 'Express' : 'Standard',
              icon: order.isExpress
                  ? Icons.bolt_rounded
                  : Icons.schedule_outlined),
          if (order.expressNote.isNotEmpty) ...[
            const Divider(),
            AppInfoRow(
                label: 'Express note',
                value: order.expressNote,
                icon: Icons.notes_rounded),
          ],
        ],
      ),
    );
  }
}

class PricingDetailCard extends StatelessWidget {
  final Order order;

  const PricingDetailCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
              title: 'Payment summary',
              subtitle: 'Order total and settlement split'),
          const SizedBox(height: AppSpacing.sm),
          AppInfoRow(label: 'Order total', value: formatLbp(order.total)),
          const Divider(),
          AppInfoRow(
              label: 'Delivery charge', value: formatLbp(order.deliveryCharge)),
          const Divider(),
          AppInfoRow(
            label: 'Merchant amount',
            value: formatLbp(order.merchantAmount),
            valueStyle:
                context.textStyles.titleMedium?.copyWith(color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

class ConfirmDeliveredDialog extends StatelessWidget {
  const ConfirmDeliveredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon:
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.teal),
      title: const Text('Mark as delivered?'),
      content: const Text(
          'This updates the order status for everyone using GoDelivery.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep current status')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark delivered')),
      ],
    );
  }
}
