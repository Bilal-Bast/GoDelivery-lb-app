import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../models/user.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';
import '../../widgets/order_action_controls.dart';

final orderStatusFilters = [
  'ALL',
  ...OrderStatusValue.values
      .where((status) => status != OrderStatusValue.unknown)
      .map((status) => status.code),
];

List<User> adminDriverChoices(Iterable<User> users) =>
    users.where((user) => user.isDriver).toList();

List<Order> filterAdminOrders(
  Iterable<Order> orders, {
  String status = 'ALL',
  String? driver,
  String? merchant,
  String search = '',
}) {
  final query = search.trim().toLowerCase();
  return orders.where((order) {
    if (status != 'ALL' && order.status != status) return false;
    if (driver != null && order.driverId != driver) return false;
    if (merchant != null && order.merchantId != merchant) return false;
    if (query.isEmpty) return true;
    return [
      order.id,
      order.customerName,
      order.customerPhone,
      order.merchantId,
      order.city,
      order.district,
    ].any((value) => value.toLowerCase().contains(query));
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  String? _selectedDriver;
  String? _selectedMerchant;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      if (context.read<AuthProvider>().currentUser?.isAdmin == true) {
        final admin = context.read<AdminProvider>();
        admin.loadUsers();
        admin.loadLocations();
      }
    });
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
    return filterAdminOrders(
      orders,
      status: _selectedStatus,
      driver: _selectedDriver,
      merchant: _selectedMerchant,
      search: _searchQuery,
    );
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
            final isAdmin =
                context.watch<AuthProvider>().currentUser?.isAdmin == true;
            final users = context.watch<AdminProvider>().users;
            return LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 960;
                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    key: const PageStorageKey('orders_list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(context.pagePadding),
                    itemCount: filtered.isEmpty
                        ? 2
                        : filtered.length + (provider.hasMoreOrders ? 2 : 1),
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
                          drivers: isAdmin
                              ? users
                                  .where((user) => user.isDriver)
                                  .map((user) => user.username)
                                  .toList()
                              : const [],
                          merchants: isAdmin
                              ? users
                                  .where((user) => user.isMerchant)
                                  .map((user) => user.username)
                                  .toList()
                              : const [],
                          selectedDriver: _selectedDriver,
                          selectedMerchant: _selectedMerchant,
                          onDriverChanged: (value) =>
                              setState(() => _selectedDriver = value),
                          onMerchantChanged: (value) =>
                              setState(() => _selectedMerchant = value),
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
                                setState(() {
                                  _selectedStatus = 'ALL';
                                  _selectedDriver = null;
                                  _selectedMerchant = null;
                                });
                              },
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Clear filters'),
                            ),
                          ),
                        );
                      }
                      if (index == filtered.length + 1) {
                        return Center(
                          child: OutlinedButton.icon(
                            key: const Key('orders_load_more_button'),
                            onPressed: provider.isLoadingMore
                                ? null
                                : provider.fetchMoreOrders,
                            icon: provider.isLoadingMore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.expand_more_rounded),
                            label: const Text('Load more orders'),
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
  final List<String> drivers;
  final List<String> merchants;
  final String? selectedDriver;
  final String? selectedMerchant;
  final ValueChanged<String?> onDriverChanged;
  final ValueChanged<String?> onMerchantChanged;

  const OrdersHeader({
    super.key,
    required this.controller,
    required this.selectedStatus,
    required this.totalCount,
    required this.visibleCount,
    required this.loading,
    required this.onStatusChanged,
    required this.onRefresh,
    this.drivers = const [],
    this.merchants = const [],
    this.selectedDriver,
    this.selectedMerchant,
    this.onDriverChanged = _ignoreNullableString,
    this.onMerchantChanged = _ignoreNullableString,
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
              if (drivers.isNotEmpty || merchants.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (drivers.isNotEmpty)
                      SizedBox(
                        width: 230,
                        child: DropdownButtonFormField<String?>(
                          key: const Key('orders_driver_filter'),
                          initialValue: selectedDriver,
                          decoration:
                              const InputDecoration(labelText: 'Driver'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All drivers')),
                            ...drivers.map((driver) => DropdownMenuItem(
                                value: driver, child: Text(driver))),
                          ],
                          onChanged: onDriverChanged,
                        ),
                      ),
                    if (merchants.isNotEmpty)
                      SizedBox(
                        width: 230,
                        child: DropdownButtonFormField<String?>(
                          key: const Key('orders_merchant_filter'),
                          initialValue: selectedMerchant,
                          decoration:
                              const InputDecoration(labelText: 'Merchant'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All merchants')),
                            ...merchants.map((merchant) => DropdownMenuItem(
                                value: merchant, child: Text(merchant))),
                          ],
                          onChanged: onMerchantChanged,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        const OrdersColumnLabels(),
      ],
    );
  }
}

void _ignoreNullableString(String? _) {}

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
                  Text(formatUsd(order.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall),
                  Text('Fee ${formatUsd(order.deliveryCharge)}',
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
                  formatUsd(order.total),
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<OrderProvider>();
      await Future.wait([
        provider.fetchOrder(widget.orderId),
        provider.fetchHistory(widget.orderId),
      ]);
      if (!mounted) return;
      if (context.read<AuthProvider>().currentUser?.isAdmin == true) {
        context.read<AdminProvider>().loadUsers();
      }
    });
  }

  void _message(bool success, String successMessage) {
    final provider = context.read<OrderProvider>();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(success ? successMessage : provider.error ?? 'Request failed'),
      backgroundColor: success ? AppColors.teal : AppColors.red,
    ));
  }

  Future<void> _afterAdminMutation(bool success, String message) async {
    if (!mounted) return;
    _message(success, message);
    if (success) {
      context.read<AdminProvider>().loadDashboard();
    }
  }

  Future<void> _editOrder(Order order) async {
    final changes = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AdminOrderEditDialog(order: order),
    );
    if (changes == null || changes.isEmpty || !mounted) return;
    final success = await context.read<OrderProvider>().updateOrder(
          order.id,
          changes,
        );
    await _afterAdminMutation(success, 'Order details updated');
  }

  Future<void> _assignDriver(Order order) async {
    final drivers = adminDriverChoices(context.read<AdminProvider>().users);
    final selection = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign driver'),
        children: [
          SimpleDialogOption(
            key: const Key('assign_driver_unassigned'),
            onPressed: () => Navigator.pop(context, '__unassigned__'),
            child: const Text('Unassigned'),
          ),
          ...drivers.map((driver) => SimpleDialogOption(
                key: Key('assign_driver_${driver.username}'),
                onPressed: () => Navigator.pop(context, driver.username),
                child: Text(driver.fullName.trim().isEmpty
                    ? driver.username
                    : '${driver.fullName.trim()} · ${driver.username}'),
              )),
        ],
      ),
    );
    if (selection == null || !mounted) return;
    final success = await context.read<OrderProvider>().updateOrder(
      order.id,
      {'driver': selection == '__unassigned__' ? null : selection},
    );
    await _afterAdminMutation(success, 'Driver assignment updated');
  }

  Future<void> _changeAdminStatus(Order order) async {
    final status = await showDialog<OrderStatusValue>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change operational status'),
        children: adminOperationalStatuses
            .where((value) =>
                value != order.statusValue &&
                value != OrderStatusValue.cancelled)
            .map((value) => SimpleDialogOption(
                  key: Key('admin_status_${value.code.toLowerCase()}'),
                  onPressed: () => Navigator.pop(context, value),
                  child: Text(value.label),
                ))
            .toList(),
      ),
    );
    if (status == null || !mounted) return;
    final success = await context
        .read<OrderProvider>()
        .updateOrderStatus(order.id, status.code);
    await _afterAdminMutation(success, 'Order status updated');
  }

  Future<void> _cancelOrder(Order order) async {
    final attribution = await showDialog<String>(
      context: context,
      builder: (context) => const AdminCancellationDialog(),
    );
    if (attribution == null || !mounted) return;
    final success =
        await context.read<OrderProvider>().cancelOrder(order.id, attribution);
    await _afterAdminMutation(success, 'Order cancelled');
  }

  Future<void> _deleteOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete order permanently?'),
        content: Text(
          'Delete ${order.id}? Financially linked orders will be rejected by the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_delete_order'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<OrderProvider>();
    final success = await provider.deleteOrder(order.id);
    if (!mounted) return;
    if (success) {
      _message(true, 'Order deleted');
      context.read<AdminProvider>().loadDashboard();
      context.pop();
    } else {
      _message(false, '');
    }
  }

  Future<void> _updateStatus(
    Order order,
    OrderMutationAction action,
  ) async {
    String? note;
    if (action != OrderMutationAction.pickUp) {
      final confirmation = await showDialog<OrderActionConfirmation>(
        context: context,
        builder: (context) => OrderActionConfirmationDialog(action: action),
      );
      if (confirmation == null || !mounted) return;
      note = confirmation.note;
    }
    final status = switch (action) {
      OrderMutationAction.pickUp => OrderStatusValue.pickedUp.code,
      OrderMutationAction.deliver => OrderStatusValue.delivered.code,
      OrderMutationAction.cancel => OrderStatusValue.cancelled.code,
    };
    final success = await context.read<OrderProvider>().updateOrderStatus(
          order.id,
          status,
          note: note,
        );
    if (!mounted) return;
    final provider = context.read<OrderProvider>();
    final updated = provider.selectedOrder;
    final user = context.read<AuthProvider>().currentUser;
    if (success && user?.isDriver == true && updated != null) {
      final driverProvider = context.read<DriverProvider>();
      driverProvider.applyOrderUpdate(updated);
      await driverProvider.fetchStats();
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Order marked ${OrderStatusStyle.from(status).label.toLowerCase()}'
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
        final role = context.watch<AuthProvider>().currentUser?.role ?? '';
        final actions = availableOrderActions(
          role: role,
          status: order.statusValue,
        );
        final updating = provider.isUpdatingOrder(order.id);
        return Scaffold(
          bottomNavigationBar: compact && actions.isNotEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: OrderActionButtons(
                      role: role,
                      status: order.statusValue,
                      updating: updating,
                      keyPrefix: 'order_detail',
                      onAction: (action) => _updateStatus(order, action),
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
                  compact && actions.isNotEmpty
                      ? AppSpacing.xxl
                      : context.pagePadding,
                ),
                child: OrderDetailContent(
                  order: order,
                  role: role,
                  showHeaderAction: !compact && actions.isNotEmpty,
                  updating: updating,
                  onAction: (action) => _updateStatus(order, action),
                  adminControls: role.toLowerCase() == 'admin'
                      ? AdminOrderControls(
                          order: order,
                          updating: updating,
                          onEdit: () => _editOrder(order),
                          onAssign: () => _assignDriver(order),
                          onStatus: () => _changeAdminStatus(order),
                          onCancel: () => _cancelOrder(order),
                          onDelete: () => _deleteOrder(order),
                        )
                      : null,
                  showHistory: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminCancellationDialog extends StatelessWidget {
  const AdminCancellationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel order?'),
      content: const Text(
        'Choose who initiated the cancellation. This affects financial eligibility.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep order'),
        ),
        TextButton(
          key: const Key('cancel_by_merchant'),
          onPressed: () => Navigator.pop(context, 'merchant'),
          child: const Text('Merchant cancelled'),
        ),
        FilledButton(
          key: const Key('cancel_by_customer'),
          onPressed: () => Navigator.pop(context, 'customer'),
          child: const Text('Customer cancelled'),
        ),
      ],
    );
  }
}

class OrderDetailContent extends StatelessWidget {
  final Order order;
  final String role;
  final bool showHeaderAction;
  final bool updating;
  final ValueChanged<OrderMutationAction> onAction;
  final Widget? adminControls;
  final bool showHistory;

  const OrderDetailContent({
    super.key,
    required this.order,
    required this.role,
    required this.showHeaderAction,
    required this.updating,
    required this.onAction,
    this.adminControls,
    this.showHistory = false,
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
              OrderActionButtons(
                role: role,
                status: order.statusValue,
                updating: updating,
                keyPrefix: 'order_detail',
                onAction: onAction,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OrderStatusHero(order: order),
        if (adminControls != null) ...[
          const SizedBox(height: AppSpacing.md),
          adminControls!,
        ],
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
        if (showHistory) ...[
          const SizedBox(height: AppSpacing.md),
          OrderHistoryCard(orderId: order.id),
        ],
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
          AppInfoRow(label: 'Order total', value: formatUsd(order.total)),
          const Divider(),
          AppInfoRow(
              label: 'Delivery charge', value: formatUsd(order.deliveryCharge)),
          const Divider(),
          AppInfoRow(
            label: 'Merchant amount',
            value: formatUsd(order.merchantAmount),
            valueStyle:
                context.textStyles.titleMedium?.copyWith(color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

class AdminOrderControls extends StatelessWidget {
  final Order order;
  final bool updating;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onStatus;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const AdminOrderControls({
    super.key,
    required this.order,
    required this.updating,
    required this.onEdit,
    required this.onAssign,
    required this.onStatus,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Admin actions',
            subtitle: 'Operational changes are validated by the server',
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (!order.hasFinancialLinks)
                OutlinedButton.icon(
                  key: const Key('admin_edit_order'),
                  onPressed: updating ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit details'),
                ),
              if (!order.hasFinancialLinks &&
                  order.statusValue != OrderStatusValue.collected &&
                  order.statusValue != OrderStatusValue.paid)
                OutlinedButton.icon(
                  key: const Key('admin_assign_driver'),
                  onPressed: updating ? null : onAssign,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(order.driverId == null
                      ? 'Assign driver'
                      : 'Reassign driver'),
                ),
              if (!order.hasFinancialLinks &&
                  order.statusValue != OrderStatusValue.collected &&
                  order.statusValue != OrderStatusValue.paid)
                OutlinedButton.icon(
                  key: const Key('admin_change_status'),
                  onPressed: updating ? null : onStatus,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Change status'),
                ),
              if (!order.isCanceled &&
                  !order.hasFinancialLinks &&
                  order.statusValue != OrderStatusValue.collected &&
                  order.statusValue != OrderStatusValue.paid)
                OutlinedButton.icon(
                  key: const Key('admin_cancel_order'),
                  onPressed: updating ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel order'),
                ),
              if (!order.hasFinancialLinks)
                OutlinedButton.icon(
                  key: const Key('admin_delete_order'),
                  onPressed: updating ? null : onDelete,
                  style:
                      OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
            ],
          ),
          if (order.hasFinancialLinks) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This order has settlement records and cannot be deleted.',
              style:
                  context.textStyles.bodySmall?.copyWith(color: AppColors.red),
            ),
          ],
        ],
      ),
    );
  }
}

Map<String, dynamic> buildAdminOrderUpdatePayload({
  required Order original,
  required String merchantUsername,
  required String customerFirstName,
  required String customerLastName,
  required String customerPhone,
  required String district,
  required String city,
  required double total,
  required double deliveryCharge,
  required bool isExpress,
  required String expressNote,
}) {
  final payload = <String, dynamic>{};
  if (merchantUsername != original.merchantId) payload['m'] = merchantUsername;
  final customer = <String, dynamic>{};
  if (customerFirstName != original.customerFirstName) {
    customer['f'] = customerFirstName;
  }
  if (customerLastName != (original.customerLastName ?? '')) {
    customer['l'] = customerLastName;
  }
  if (customerPhone != original.customerPhone) customer['p'] = customerPhone;
  final location = <String, dynamic>{};
  if (district != original.district) location['d'] = district;
  if (city != original.city) location['cty'] = city;
  if (location.isNotEmpty) customer['loc'] = location;
  if (customer.isNotEmpty) payload['c'] = customer;
  final pricing = <String, dynamic>{};
  if (total != original.total) pricing['t'] = total;
  if (deliveryCharge != original.deliveryCharge) {
    pricing['d'] = deliveryCharge;
  }
  if (pricing.isNotEmpty) payload['pr'] = pricing;
  if (isExpress != original.isExpress) payload['e'] = isExpress;
  if (expressNote != original.expressNote) payload['eN'] = expressNote;
  return payload;
}

class AdminOrderEditDialog extends StatefulWidget {
  final Order order;

  const AdminOrderEditDialog({super.key, required this.order});

  @override
  State<AdminOrderEditDialog> createState() => _AdminOrderEditDialogState();
}

class _AdminOrderEditDialogState extends State<AdminOrderEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _total;
  late final TextEditingController _deliveryCharge;
  late final TextEditingController _expressNote;
  late String _merchant;
  late String _district;
  late String _city;
  late bool _express;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _firstName = TextEditingController(text: order.customerFirstName);
    _lastName = TextEditingController(text: order.customerLastName ?? '');
    _phone = TextEditingController(text: order.customerPhone);
    _total = TextEditingController(text: order.total.toString());
    _deliveryCharge =
        TextEditingController(text: order.deliveryCharge.toString());
    _expressNote = TextEditingController(text: order.expressNote);
    _merchant = order.merchantId;
    _district = order.district;
    _city = order.city;
    _express = order.isExpress;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _total.dispose();
    _deliveryCharge.dispose();
    _expressNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final merchants = admin.users.where((user) => user.isMerchant).toList();
    final districts = admin.locations;
    final selectedDistrict =
        districts.where((district) => district.nameEn == _district).firstOrNull;
    final cities = selectedDistrict?.cities ?? const [];
    return AlertDialog(
      title: const Text('Edit order'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _merchant,
                  decoration: const InputDecoration(labelText: 'Merchant'),
                  items: {
                    _merchant,
                    ...merchants.map((user) => user.username),
                  }
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _merchant = value!),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'First name is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _lastName,
                  decoration:
                      const InputDecoration(labelText: 'Last name (optional)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Phone is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _district,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: {
                    _district,
                    ...districts.map((item) => item.nameEn),
                  }
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _district = value!;
                    final match = districts
                        .where((item) => item.nameEn == value)
                        .firstOrNull;
                    _city = match?.cities.firstOrNull?.nameEn ?? '';
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _city.isEmpty ? null : _city,
                  decoration: const InputDecoration(labelText: 'City'),
                  items: {
                    if (_city.isNotEmpty) _city,
                    ...cities.map((item) => item.nameEn),
                  }
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _city = value!),
                  validator: (value) => value == null || value.isEmpty
                      ? 'City is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _total,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total'),
                  validator: _moneyValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _deliveryCharge,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Delivery charge'),
                  validator: _moneyValidator,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Express'),
                  value: _express,
                  onChanged: (value) => setState(() => _express = value),
                ),
                TextFormField(
                  controller: _expressNote,
                  decoration: const InputDecoration(labelText: 'Express note'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save_admin_order_edit'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              buildAdminOrderUpdatePayload(
                original: widget.order,
                merchantUsername: _merchant,
                customerFirstName: _firstName.text.trim(),
                customerLastName: _lastName.text.trim(),
                customerPhone: _phone.text.trim(),
                district: _district,
                city: _city,
                total: double.parse(_total.text.trim()),
                deliveryCharge: double.parse(_deliveryCharge.text.trim()),
                isExpress: _express,
                expressNote: _expressNote.text.trim(),
              ),
            );
          },
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}

String? _moneyValidator(String? value) {
  final amount = double.tryParse(value?.trim() ?? '');
  if (amount == null) return 'Enter a valid amount';
  if (amount < 0) return 'Amount cannot be negative';
  return null;
}

class OrderHistoryCard extends StatelessWidget {
  final String orderId;

  const OrderHistoryCard({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(builder: (context, provider, child) {
      return AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Order history',
              subtitle: 'Lifecycle and admin audit trail',
              trailing: IconButton(
                tooltip: 'Refresh history',
                onPressed: provider.isHistoryLoading
                    ? null
                    : () => provider.fetchHistory(orderId),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (provider.isHistoryLoading && provider.history.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.historyError != null)
              AppErrorState(
                title: 'History unavailable',
                message: provider.historyError!,
                onRetry: () => provider.fetchHistory(orderId),
              )
            else if (provider.history.isEmpty)
              const AppEmptyState(
                title: 'No history yet',
                message: 'Successful changes will appear here.',
                icon: Icons.history_rounded,
              )
            else
              ...provider.history.map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(_historyTitle(entry)),
                    subtitle: Text(
                      '${_historyDetail(entry)}\nBy ${entry.performedBy} · ${DateFormat('MMM d, yyyy · HH:mm').format(entry.createdAt.toLocal())}',
                    ),
                    isThreeLine: true,
                  )),
          ],
        ),
      );
    });
  }
}

String _historyTitle(OrderHistoryEntry entry) => switch (entry.actionType) {
      'creation' => 'Order created',
      'status_change' => 'Status changed',
      'cancellation' => 'Order cancelled',
      'update' => 'Order details updated',
      _ => 'Order updated',
    };

String _historyDetail(OrderHistoryEntry entry) {
  final statusText = entry.metadata['status_text']?.toString();
  final cancelledBy = entry.metadata['cancelledBy']?.toString();
  final note = entry.metadata['note']?.toString();
  final parts = <String>[
    if (statusText != null && statusText.isNotEmpty) 'New status: $statusText',
    if (cancelledBy != null && cancelledBy.isNotEmpty)
      'Initiated by $cancelledBy',
    if (note != null && note.isNotEmpty) note,
  ];
  if (parts.isNotEmpty) return parts.join(' · ');
  if (entry.actionType == 'update' && entry.newValue is Map) {
    final keys = (entry.newValue as Map)
        .keys
        .map((key) => _historyFieldLabel(key.toString()))
        .toSet()
        .join(', ');
    if (keys.isNotEmpty) return 'Changed: $keys';
  }
  return 'Recorded by the order service';
}

String _historyFieldLabel(String key) => switch (key) {
      'm' => 'merchant',
      'driver' => 'driver',
      'c' => 'customer or location',
      'pr' => 'pricing',
      'e' => 'express service',
      'eN' => 'express note',
      's' => 'status',
      _ => 'order details',
    };

extension _FirstOrNullIterable<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
