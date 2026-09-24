import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_tokens.dart';
import '../models/collection.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../providers/providers.dart';
import '../widgets/app_components.dart';

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

  Future<void> _load() {
    return context.read<DriverProvider>().fetchDriverOrders(
          status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        );
  }

  Future<void> _changeStatus(Order order, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DriverStatusActionDialog(status: status),
    );
    if (confirmed != true || !mounted) return;
    final success = await context
        .read<DriverProvider>()
        .updateOrderStatus(order.id, status);
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
                      onStatusChanged: (status) {
                        setState(() => _selectedStatus = status);
                        _load();
                      },
                      onRefresh: _load,
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
                    updating: provider.isLoading,
                    onDelivered: () => _changeStatus(
                        provider.driverOrders[index - 1], 'DELIVERED'),
                    onCancelled: () => _changeStatus(
                        provider.driverOrders[index - 1], 'CANCELLED'),
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
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function() onRefresh;

  const DriverOrdersHeader({
    super.key,
    required this.selectedStatus,
    required this.orders,
    required this.onStatusChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final active = orders
        .where((order) => order.status == 'NEW' || order.status == 'PICKED_UP')
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'My deliveries',
          subtitle: '$active active · ${orders.length} shown',
          actions: [
            OutlinedButton.icon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
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
  final VoidCallback onDelivered;
  final VoidCallback onCancelled;

  const DriverDeliveryCard({
    super.key,
    required this.order,
    required this.updating,
    required this.onDelivered,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final actionable = order.status == 'NEW' ||
        order.status == 'PICKED_UP' ||
        order.status == 'WAREHOUSE';
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
          if (actionable) ...[
            const Divider(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final delivered = FilledButton.icon(
                  key: Key('driver_delivered_${order.id}'),
                  onPressed: updating ? null : onDelivered,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Delivered'),
                );
                final cancelled = OutlinedButton.icon(
                  key: Key('driver_cancelled_${order.id}'),
                  onPressed: updating ? null : onCancelled,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelled'),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      delivered,
                      const SizedBox(height: AppSpacing.xs),
                      cancelled
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: delivered),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: cancelled),
                  ],
                );
              },
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
              value: formatLbp(order.total)),
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

class DriverStatusActionDialog extends StatelessWidget {
  final String status;

  const DriverStatusActionDialog({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final delivered = status == 'DELIVERED';
    return AlertDialog(
      icon: Icon(
          delivered
              ? Icons.check_circle_outline_rounded
              : Icons.cancel_outlined,
          color: delivered ? AppColors.teal : AppColors.red),
      title: Text('Mark as ${statusLabel(status).toLowerCase()}?'),
      content: Text(delivered
          ? 'Confirm that the order reached the customer.'
          : 'Confirm that this delivery was cancelled. This status is visible to operations.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm')),
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DriverProvider>().fetchCollections(),
    );
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
                      onRetry: provider.fetchCollections,
                    ),
                  ),
                ],
              );
            }
            return CollectionsList(
                collections: provider.collections,
                onRefresh: provider.fetchCollections);
          },
        ),
      ),
    );
  }
}

class CollectionsList extends StatelessWidget {
  final List<DriverCollection> collections;
  final Future<void> Function() onRefresh;

  const CollectionsList(
      {super.key, required this.collections, required this.onRefresh});

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
            return const AppPageHeader(
                title: 'Collections',
                subtitle: 'Cash collection and commission history');
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
                      value: formatLbp(collection.amount))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: DeliveryFact(
                      icon: Icons.savings_outlined,
                      label: 'Commission',
                      value: formatLbp(collection.deliveryFee))),
            ],
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
      (_) => context.read<OrderProvider>().fetchOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.orders.isEmpty) {
              return const AppLoadingState(
                  message: 'Loading merchant overview…');
            }
            if (provider.error != null && provider.orders.isEmpty) {
              return AppErrorState(
                  title: 'Overview unavailable',
                  message: provider.error!,
                  onRetry: provider.fetchOrders);
            }
            return MerchantOverview(
                orders: provider.orders, onRefresh: provider.fetchOrders);
          },
        ),
      ),
    );
  }
}

class MerchantOverview extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;

  const MerchantOverview(
      {super.key, required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final delivered = orders
        .where((order) =>
            const {'DELIVERED', 'PAID', 'COLLECTED'}.contains(order.status))
        .toList();
    final active = orders
        .where((order) =>
            const {'WAREHOUSE', 'NEW', 'PICKED_UP'}.contains(order.status))
        .length;
    final sales =
        delivered.fold<double>(0, (sum, order) => sum + order.merchantAmount);
    final orderValue = orders
        .where((order) => !order.isCanceled)
        .fold<double>(0, (sum, order) => sum + order.total);
    final recent = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                    subtitle:
                        'Sales, orders and account information in one place.',
                    eyebrow: AccountPlanBadge(accountType: user?.accountType),
                    actions: [
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
                          label: 'Delivered sales',
                          value: formatLbp(sales),
                          icon: Icons.trending_up_rounded,
                          color: AppColors.teal),
                      AppMetricCard(
                          label: 'Order value',
                          value: formatLbp(orderValue),
                          icon: Icons.payments_outlined,
                          color: AppColors.blue),
                      AppMetricCard(
                          label: 'All orders',
                          value: '${orders.length}',
                          hint: '$active active',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.violet),
                      AppMetricCard(
                          label: 'Delivered orders',
                          value: '${delivered.length}',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.brand),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MerchantAccountCard(user: user),
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionHeader(
                    title: 'Recent activity',
                    subtitle: 'Latest customer orders',
                    trailing: TextButton(
                        onPressed: () => context.go('/home/orders'),
                        child: const Text('View all')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (recent.isEmpty)
                    const AppSurfaceCard(
                        child: AppEmptyState(
                            title: 'No orders yet',
                            message:
                                'Create an order to begin tracking merchant activity.'))
                  else
                    AppSurfaceCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < recent.take(6).length;
                              index++) ...[
                            MerchantOrderRow(order: recent[index]),
                            if (index != recent.take(6).length - 1)
                              const Divider(),
                          ],
                        ],
                      ),
                    ),
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
                  : formatLbp(user!.deliveryFee!),
              icon: Icons.local_shipping_outlined),
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
        child: Row(
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
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatLbp(order.total),
                    style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                OrderStatusBadge(status: order.status, showIcon: false),
              ],
            ),
          ],
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
          Text(formatLbp(payment.amount),
              style: context.textStyles.titleMedium
                  ?.copyWith(color: AppColors.teal)),
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
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                      subtitle: const Text('Delivery and account alerts'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
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
        ),
      ),
    );
  }
}

String statusLabel(String status) {
  if (status == 'ALL') return 'All';
  return OrderStatusStyle.from(status).label;
}
