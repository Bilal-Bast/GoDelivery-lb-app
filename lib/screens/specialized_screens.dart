import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_tokens.dart';
import '../models/collection.dart';
import '../models/driver_stats.dart';
import '../models/finance.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';
import '../models/app_notification.dart';
import '../widgets/app_components.dart';
import '../widgets/order_action_controls.dart';
import '../widgets/order_scanner.dart';
import 'reports/statement_screen.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<DriverProvider>();
    await Future.wait([
      provider.fetchDriverOrders(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      ),
      provider.fetchStats(),
    ]);
  }

  Future<void> _changeStatus(
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
    final success = await context
        .read<DriverProvider>()
        .updateOrderStatus(order.id, status, note: note);
    if (!mounted) return;
    final provider = context.read<DriverProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Order marked ${statusLabel(status).toLowerCase()}'
            : provider.error ?? 'Status update failed'),
        backgroundColor: success ? AppColors.teal : AppColors.red,
      ),
    );
  }

  Future<void> _scanOrder() async {
    final provider = context.read<DriverProvider>();
    final result = await showOrderScanner(
      context,
      title: 'Find assigned delivery',
      closeAfterSuccess: true,
      process: (orderId) async {
        final order = await provider.lookupAssignedOrder(orderId);
        if (order != null) {
          return OrderScanResult(
            kind: ScanResultKind.valid,
            orderId: orderId,
            data: order,
            message: 'Assigned order found',
          );
        }
        final message = provider.error ?? 'Order not found';
        return OrderScanResult(
          kind: message.toLowerCase().contains('not found')
              ? ScanResultKind.notFound
              : ScanResultKind.unauthorized,
          orderId: orderId,
          message: message,
        );
      },
    );
    if (!mounted || result?.isSuccess != true) return;
    await _showScannedOrder();
  }

  Future<void> _showScannedOrder() async {
    var scanNext = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.md,
          ),
          child: Consumer<DriverProvider>(
            builder: (context, provider, child) {
              final order = provider.scannedOrder;
              if (order == null) {
                return const AppErrorState(message: 'Order is unavailable.');
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DriverDeliveryCard(
                      order: order,
                      updating: provider.isUpdatingOrder(order.id),
                      onAction: (action) => _changeStatus(order, action),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: provider.isUpdatingOrder(order.id)
                            ? null
                            : () {
                                scanNext = true;
                                Navigator.of(sheetContext).pop();
                              },
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Scan next'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    if (scanNext && mounted) await _scanOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DriverProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.driverOrders.isEmpty) {
              return const AppLoadingState(
                  message: 'Loading assigned deliveries…');
            }
            if (provider.error != null && provider.driverOrders.isEmpty) {
              return AppErrorState(
                title: 'Deliveries unavailable',
                message: provider.error!,
                onRetry: _load,
              );
            }
            return RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(context.pagePadding),
                itemCount: provider.driverOrders.isEmpty
                    ? 2
                    : provider.driverOrders.length + 1,
                separatorBuilder: (context, index) => SizedBox(
                    height: index == 0 ? AppSpacing.lg : AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return DriverOrdersHeader(
                      selectedStatus: _selectedStatus,
                      orders: provider.driverOrders,
                      stats: provider.stats,
                      onStatusChanged: (status) {
                        setState(() => _selectedStatus = status);
                        context.read<DriverProvider>().fetchDriverOrders(
                              status: status == 'ALL' ? null : status,
                            );
                      },
                      onRefresh: _load,
                      onScan: _scanOrder,
                    );
                  }
                  if (provider.driverOrders.isEmpty) {
                    return const AppSurfaceCard(
                      child: AppEmptyState(
                        title: 'Route clear',
                        message:
                            'There are no deliveries assigned in this status.',
                        icon: Icons.route_outlined,
                      ),
                    );
                  }
                  return DriverDeliveryCard(
                    order: provider.driverOrders[index - 1],
                    updating: provider.isUpdatingOrder(
                      provider.driverOrders[index - 1].id,
                    ),
                    onAction: (action) => _changeStatus(
                      provider.driverOrders[index - 1],
                      action,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class DriverOrdersHeader extends StatelessWidget {
  final String selectedStatus;
  final List<Order> orders;
  final DriverStats? stats;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onScan;

  const DriverOrdersHeader({
    super.key,
    required this.selectedStatus,
    required this.orders,
    required this.stats,
    required this.onStatusChanged,
    required this.onRefresh,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final active = orders
        .where((order) =>
            order.statusValue.isPending ||
            order.statusValue == OrderStatusValue.pickedUp)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'My deliveries',
          subtitle: '$active active · ${orders.length} shown',
          actions: [
            if (onScan != null)
              FilledButton.icon(
                key: const Key('driver_scan_button'),
                onPressed: () => onScan!(),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan'),
              ),
            OutlinedButton.icon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (stats != null) ...[
          AppResponsiveGrid(
            minItemWidth: 180,
            children: [
              AppMetricCard(
                label: 'Total deliveries',
                value: stats!.totalDeliveries.toString(),
                icon: Icons.local_shipping_outlined,
                color: AppColors.teal,
              ),
              AppMetricCard(
                label: "Today's deliveries",
                value: stats!.todaysDeliveries.toString(),
                icon: Icons.today_outlined,
                color: AppColors.blue,
              ),
              AppMetricCard(
                label: 'Active orders',
                value: stats!.activeOrders.toString(),
                icon: Icons.route_outlined,
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0;
                  index < const ['ALL', 'NEW', 'PICKED_UP', 'DELIVERED'].length;
                  index++) ...[
                FilterChip(
                  label: Text(statusLabel(
                      const ['ALL', 'NEW', 'PICKED_UP', 'DELIVERED'][index])),
                  selected: selectedStatus ==
                      const ['ALL', 'NEW', 'PICKED_UP', 'DELIVERED'][index],
                  showCheckmark: false,
                  onSelected: (_) => onStatusChanged(
                      const ['ALL', 'NEW', 'PICKED_UP', 'DELIVERED'][index]),
                ),
                if (index != 3) const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DriverDeliveryCard extends StatelessWidget {
  final Order order;
  final bool updating;
  final ValueChanged<OrderMutationAction> onAction;

  const DriverDeliveryCard({
    super.key,
    required this.order,
    required this.updating,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actionable = availableOrderActions(
      role: 'driver',
      status: order.statusValue,
    );
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      emphasized: order.isExpress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.person_pin_circle_outlined,
                    color: AppColors.brandStrong),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        order.customerName.isEmpty
                            ? 'Unknown customer'
                            : order.customerName,
                        style: context.textStyles.titleMedium),
                    Text('#${shortIdentifier(order.id, length: 12)}',
                        style: context.textStyles.bodySmall),
                  ],
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DriverDeliveryFacts(order: order),
          if (order.isExpress && order.expressNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.amber, size: 19),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                      child: Text(order.expressNote,
                          style: context.textStyles.bodySmall)),
                ],
              ),
            ),
          ],
          if (actionable.isNotEmpty) ...[
            const Divider(height: AppSpacing.lg),
            OrderActionButtons(
              role: 'driver',
              status: order.statusValue,
              updating: updating,
              onAction: onAction,
              keyPrefix: 'driver_${order.id}',
            ),
          ],
        ],
      ),
    );
  }
}

class DriverDeliveryFacts extends StatelessWidget {
  final Order order;

  const DriverDeliveryFacts({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final facts = [
          DeliveryFact(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: order.customerPhone.isEmpty
                  ? 'Not provided'
                  : order.customerPhone),
          DeliveryFact(
              icon: Icons.location_on_outlined,
              label: 'Destination',
              value: [order.city, order.district]
                  .where((value) => value.isNotEmpty)
                  .join(', ')),
          DeliveryFact(
              icon: Icons.payments_outlined,
              label: 'Order value',
              value: formatUsd(order.total)),
        ];
        if (constraints.maxWidth < 680) {
          return Column(
            children: [
              for (var index = 0; index < facts.length; index++) ...[
                facts[index],
                if (index != facts.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < facts.length; index++) ...[
              Expanded(child: facts[index]),
              if (index != facts.length - 1)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class DeliveryFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DeliveryFact(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textStyles.bodySmall),
              const SizedBox(height: 2),
              Text(value.isEmpty ? 'Not provided' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class DriverCollectionsScreen extends StatefulWidget {
  const DriverCollectionsScreen({super.key});

  @override
  State<DriverCollectionsScreen> createState() =>
      _DriverCollectionsScreenState();
}

class _DriverCollectionsScreenState extends State<DriverCollectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<DriverProvider>();
    await Future.wait([provider.fetchCollections(), provider.fetchBalance()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DriverProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.collections.isEmpty) {
              return const AppLoadingState(message: 'Loading collections…');
            }
            if (provider.error != null && provider.collections.isEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(context.pagePadding),
                    child: const AppPageHeader(
                      title: 'Collections',
                      subtitle: 'Cash collection and commission history',
                    ),
                  ),
                  Expanded(
                    child: AppErrorState(
                      title: 'Collection history is not available',
                      message: provider.error!,
                      onRetry: _load,
                    ),
                  ),
                ],
              );
            }
            return CollectionsList(
              collections: provider.collections,
              balance: provider.balance,
              balanceError: provider.balanceError,
              isBalanceLoading: provider.isBalanceLoading,
              onRefresh: _load,
              onBalanceRetry: provider.fetchBalance,
            );
          },
        ),
      ),
    );
  }
}

class CollectionsList extends StatelessWidget {
  final List<DriverCollection> collections;
  final DriverBalance? balance;
  final String? balanceError;
  final bool isBalanceLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onBalanceRetry;

  const CollectionsList({
    super.key,
    required this.collections,
    required this.balance,
    required this.balanceError,
    required this.isBalanceLoading,
    required this.onRefresh,
    required this.onBalanceRetry,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(context.pagePadding),
        itemCount: collections.isEmpty ? 2 : collections.length + 1,
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? AppSpacing.lg : AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                    title: 'Collections',
                    subtitle: 'Cash collection and commission history',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const StatementScreen(kind: 'driver'))),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Statement'),
                      )
                    ]),
                const SizedBox(height: AppSpacing.lg),
                if (balance != null)
                  AppResponsiveGrid(
                    children: [
                      AppMetricCard(
                        key: const Key('driver_outstanding_balance'),
                        label: 'Outstanding balance',
                        value: formatUsd(balance!.outstanding),
                        hint: '${balance!.orderCount} unsettled orders',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.amber,
                      ),
                    ],
                  )
                else if (isBalanceLoading)
                  const AppLoadingState(message: 'Loading balance…')
                else if (balanceError != null)
                  AppSurfaceCard(
                    child: AppErrorState(
                      title: 'Balance unavailable',
                      message: balanceError!,
                      onRetry: onBalanceRetry,
                    ),
                  ),
              ],
            );
          }
          if (collections.isEmpty) {
            return const AppSurfaceCard(
              child: AppEmptyState(
                  title: 'No collections yet',
                  message: 'Your collection history will appear here.',
                  icon: Icons.account_balance_wallet_outlined),
            );
          }
          return CollectionCard(collection: collections[index - 1]);
        },
      ),
    );
  }
}

class CollectionCard extends StatelessWidget {
  final DriverCollection collection;

  const CollectionCard({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Collection #${collection.number}',
                      style: context.textStyles.titleMedium)),
              Text(DateFormat('MMM d, yyyy').format(collection.createdAt),
                  style: context.textStyles.bodySmall),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                  child: DeliveryFact(
                      icon: Icons.payments_outlined,
                      label: 'Collected',
                      value: formatUsd(collection.amount))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: DeliveryFact(
                      icon: Icons.savings_outlined,
                      label: 'Commission',
                      value: formatUsd(collection.deliveryFee))),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${collection.orderCount} linked ${collection.orderCount == 1 ? 'order' : 'orders'}',
              style: context.textStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class MerchantBalanceScreen extends StatefulWidget {
  const MerchantBalanceScreen({super.key});

  @override
  State<MerchantBalanceScreen> createState() => _MerchantBalanceScreenState();
}

class _MerchantBalanceScreenState extends State<MerchantBalanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MerchantProvider>().fetchBalance(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<MerchantProvider>(
          builder: (context, provider, child) {
            if (provider.balance == null && provider.error == null) {
              return const AppLoadingState(
                  message: 'Loading merchant overview…');
            }
            if (provider.error != null && provider.balance == null) {
              return AppErrorState(
                  title: 'Balance unavailable',
                  message: provider.error!,
                  onRetry: provider.fetchBalance);
            }
            return MerchantOverview(
              balance: provider.balance!,
              onRefresh: provider.fetchBalance,
            );
          },
        ),
      ),
    );
  }
}

class MerchantOverview extends StatelessWidget {
  final MerchantBalance balance;
  final Future<void> Function() onRefresh;

  const MerchantOverview({
    super.key,
    required this.balance,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: 'Merchant overview',
                    subtitle: 'Authoritative balance and account information.',
                    eyebrow: AccountPlanBadge(accountType: balance.accountType),
                    actions: [
                      OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const StatementScreen(kind: 'merchant'))),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Statement')),
                      OutlinedButton.icon(
                          onPressed: () => onRefresh(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh')),
                      FilledButton.icon(
                          onPressed: () => context.push('/home/create-order'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New order')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppResponsiveGrid(
                    children: [
                      AppMetricCard(
                          key: const Key('merchant_authoritative_balance'),
                          label: 'Current balance',
                          value: formatUsd(balance.balance),
                          icon: Icons.trending_up_rounded,
                          color: AppColors.teal),
                      AppMetricCard(
                          label: 'Entitled',
                          value: formatUsd(balance.entitled),
                          icon: Icons.payments_outlined,
                          color: AppColors.blue),
                      AppMetricCard(
                          label: 'Paid',
                          value: formatUsd(balance.paid),
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.violet),
                      AppMetricCard(
                          label: 'Balance orders',
                          value: '${balance.orderCount}',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.brand),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MerchantAccountCard(user: user),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountPlanBadge extends StatelessWidget {
  final String? accountType;

  const AccountPlanBadge({super.key, required this.accountType});

  @override
  Widget build(BuildContext context) {
    final label = accountType?.trim().toUpperCase();
    if (label == null || label.isEmpty) return const SizedBox.shrink();
    final color = label == 'PREPAID' ? AppColors.teal : AppColors.amber;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text('$label ACCOUNT',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .5)),
      ),
    );
  }
}

class MerchantAccountCard extends StatelessWidget {
  final User? user;

  const MerchantAccountCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
              title: 'Account information',
              subtitle: 'Payment plan and configured merchant settings'),
          const SizedBox(height: AppSpacing.sm),
          AppInfoRow(
              label: 'Account type',
              value: user?.accountType?.toUpperCase() ?? 'Not configured',
              icon: Icons.account_balance_wallet_outlined),
          const Divider(),
          AppInfoRow(
              label: 'Payment day',
              value: user?.paymentDay ?? 'Not configured',
              icon: Icons.event_outlined),
          const Divider(),
          AppInfoRow(
              label: 'Order ID prefix',
              value: user?.orderIdPrefix ?? 'Not configured',
              icon: Icons.tag_rounded),
          const Divider(),
          AppInfoRow(
              label: 'Default delivery fee',
              value: user?.deliveryFee == null
                  ? 'Not configured'
                  : formatUsd(user!.deliveryFee!),
              icon: Icons.local_shipping_outlined),
          if (user?.accountType?.toUpperCase() == 'PREPAID') ...[
            const Divider(),
            AppInfoRow(
                label: 'Legacy balance',
                value: formatUsd(user?.legacyBalance ?? 0),
                icon: Icons.history_rounded),
          ],
          if (user?.deliveryCharges.isNotEmpty == true) ...[
            const Divider(),
            AppInfoRow(
                label: 'Delivery charges',
                value: user!.deliveryCharges.entries
                    .map((entry) => '${entry.key}: ${formatUsd(entry.value)}')
                    .join(' · '),
                icon: Icons.map_outlined),
          ],
        ],
      ),
    );
  }
}

class MerchantOrderRow extends StatelessWidget {
  final Order order;

  const MerchantOrderRow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/home/orders/${order.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identity = Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.brandStrong, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          order.customerName.isEmpty
                              ? '#${shortIdentifier(order.id)}'
                              : order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.titleSmall),
                      Text(
                          '${order.city} · ${DateFormat('MMM d, HH:mm').format(order.createdAt.toLocal())}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            );
            final amount = Text(
              formatUsd(order.total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: context.textStyles.titleSmall,
            );
            final status =
                OrderStatusBadge(status: order.status, showIcon: false);

            if (constraints.maxWidth < 360) {
              return Column(
                children: [
                  identity,
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: amount),
                      const SizedBox(width: AppSpacing.sm),
                      status,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      amount,
                      const SizedBox(height: AppSpacing.xxs),
                      status,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MerchantPaymentsScreen extends StatefulWidget {
  const MerchantPaymentsScreen({super.key});

  @override
  State<MerchantPaymentsScreen> createState() => _MerchantPaymentsScreenState();
}

class _MerchantPaymentsScreenState extends State<MerchantPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MerchantProvider>().fetchPayments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<MerchantProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.payments.isEmpty) {
              return const AppLoadingState(message: 'Loading payment history…');
            }
            if (provider.error != null && provider.payments.isEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(context.pagePadding),
                    child: const AppPageHeader(
                        title: 'Payments',
                        subtitle: 'Merchant settlement history'),
                  ),
                  Expanded(
                    child: AppErrorState(
                      title: 'Payment history is not available',
                      message: provider.error!,
                      onRetry: provider.fetchPayments,
                    ),
                  ),
                ],
              );
            }
            return MerchantPaymentsList(
                payments: provider.payments, onRefresh: provider.fetchPayments);
          },
        ),
      ),
    );
  }
}

class MerchantPaymentsList extends StatelessWidget {
  final List<MerchantPayment> payments;
  final Future<void> Function() onRefresh;

  const MerchantPaymentsList(
      {super.key, required this.payments, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(context.pagePadding),
        itemCount: payments.isEmpty ? 2 : payments.length + 1,
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? AppSpacing.lg : AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const AppPageHeader(
                title: 'Payments', subtitle: 'Merchant settlement history');
          }
          if (payments.isEmpty) {
            return const AppSurfaceCard(
                child: AppEmptyState(
                    title: 'No payments yet',
                    message: 'Payment records will appear here when available.',
                    icon: Icons.receipt_long_outlined));
          }
          return MerchantPaymentCard(payment: payments[index - 1]);
        },
      ),
    );
  }
}

class MerchantPaymentCard extends StatelessWidget {
  final MerchantPayment payment;

  const MerchantPaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final paymentType = !payment.isAdvance
        ? 'Settlement'
        : payment.amount < 0
            ? 'Cash-back adjustment'
            : 'Advance';
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.tealSoft,
            foregroundColor: AppColors.teal,
            child: Icon(Icons.payments_outlined),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment #${payment.number}',
                    style: context.textStyles.titleSmall),
                Text(
                  '$paymentType · ${payment.orderCount} linked ${payment.orderCount == 1 ? 'order' : 'orders'}',
                  style: context.textStyles.bodySmall,
                ),
                Text(
                    DateFormat('MMM d, yyyy · HH:mm')
                        .format(payment.createdAt.toLocal()),
                    style: context.textStyles.bodySmall),
                if (payment.notes.isNotEmpty)
                  Text(payment.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall),
              ],
            ),
          ),
          Flexible(
            child: Text(
              formatUsd(payment.amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: context.textStyles.titleMedium?.copyWith(
                  color: payment.amount < 0 ? AppColors.red : AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: AppContent(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppPageHeader(
                    title: 'Profile',
                    subtitle: 'Your GoDelivery account details'),
                const SizedBox(height: AppSpacing.lg),
                ProfileIdentityCard(user: user),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _showSelfPasswordDialog(context),
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Change password'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('profile_logout_button'),
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/');
                    },
                    icon:
                        const Icon(Icons.logout_rounded, color: AppColors.red),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSelfPasswordDialog(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password')),
          TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
          TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Change password'),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      if (next.text != confirm.text || next.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Passwords must match and meet the requirements.')),
        );
      } else {
        final success = await context.read<AuthProvider>().changePassword(
              current.text,
              next.text,
            );
        if (context.mounted) {
          final error = context.read<AuthProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(success
                    ? 'Password changed.'
                    : error ?? 'Password change failed.')),
          );
        }
      }
    }
    current.dispose();
    next.dispose();
    confirm.dispose();
  }
}

class ProfileIdentityCard extends StatelessWidget {
  final User? user;

  const ProfileIdentityCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : user?.username ?? 'Account';
    return AppSurfaceCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.brandSoft,
            foregroundColor: AppColors.brandStrong,
            child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: context.textStyles.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name, style: context.textStyles.titleLarge),
          Text('@${user?.username ?? ''}', style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          AppInfoRow(
              label: 'Role',
              value: user?.role.toUpperCase() ?? 'Unknown',
              icon: Icons.badge_outlined),
          const Divider(),
          AppInfoRow(
              label: 'Phone',
              value: user?.phone?.isNotEmpty == true
                  ? user!.phone!
                  : 'Not provided',
              icon: Icons.phone_outlined),
          const Divider(),
          AppInfoRow(
              label: 'Email',
              value: user?.email?.isNotEmpty == true
                  ? user!.email!
                  : 'Not provided',
              icon: Icons.email_outlined),
          if (user?.accountType != null) ...[
            const Divider(),
            AppInfoRow(
                label: 'Account type',
                value: user!.accountType!.toUpperCase(),
                icon: Icons.account_balance_wallet_outlined),
          ],
          if (user?.deliveryFee != null) ...[
            const Divider(),
            AppInfoRow(
                label: 'Driver delivery fee',
                value: formatUsd(user!.deliveryFee!),
                icon: Icons.local_shipping_outlined),
          ],
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationService>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
            child: AppContent(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(
                  title: 'Settings',
                  subtitle: 'Application preferences and support'),
              const SizedBox(height: AppSpacing.lg),
              AppSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      minTileHeight: 64,
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: Text(notifications.permissionState ==
                              NotificationPermissionState.unsupported
                          ? 'Recent activity is available in app. Push is not configured.'
                          : 'Permission: ${notifications.permissionState.name}'),
                      trailing: notifications.platform.supported
                          ? const Icon(Icons.chevron_right_rounded)
                          : null,
                      onTap: !notifications.platform.supported ||
                              notifications.permissionState ==
                                  NotificationPermissionState.granted
                          ? null
                          : notifications.permissionState ==
                                  NotificationPermissionState.settingsRequired
                              ? notifications.openSystemSettings
                              : notifications.requestPermission,
                    ),
                    if (notifications.recent.isNotEmpty)
                      for (final item in notifications.recent.take(5))
                        ListTile(
                          title: Text(item.body),
                          subtitle:
                              Text(item.createdAt?.toLocal().toString() ?? ''),
                          onTap: () => notifications.open(item),
                        ),
                    if (notifications.error != null)
                      ListTile(
                        title: Text(notifications.error!),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: notifications.poll,
                        ),
                      ),
                    if (kDebugMode)
                      ListTile(
                        title: const Text('Preview notification'),
                        subtitle: const Text('Local debug preview only'),
                        onTap: () => notifications.simulateForDebug(
                            AppNotification(
                                id: 'debug-preview',
                                type: context
                                            .read<AuthProvider>()
                                            .currentUser
                                            ?.isAdmin ==
                                        true
                                    ? 'ORDER_CREATED'
                                    : context
                                                .read<AuthProvider>()
                                                .currentUser
                                                ?.isDriver ==
                                            true
                                        ? 'ORDER_ASSIGNED'
                                        : 'ORDER_DELIVERED',
                                entityType: 'order',
                                entityId: 'preview',
                                title: 'GoDelivery update',
                                body: 'Notification preview')),
                      ),
                    const Divider(),
                    ListTile(
                      minTileHeight: 64,
                      leading: const Icon(Icons.help_outline_rounded),
                      title: const Text('Help & support'),
                      subtitle: const Text('Contact the GoDelivery team'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}

String statusLabel(String status) {
  if (status == 'ALL') return 'All';
  return OrderStatusStyle.from(status).label;
}
