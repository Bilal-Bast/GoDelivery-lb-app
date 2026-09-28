import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/admin_models.dart';
import '../../models/user.dart';
import '../../providers/providers.dart';
import '../../providers/analytics_provider.dart';
import '../../services/api_service.dart';
import '../orders/order_csv_dialog.dart';
import '../../widgets/app_components.dart';
import 'admin_financial_operations.dart';
import 'admin_user_management.dart';
import 'admin_settings_controls.dart';
import 'advanced_analytics_screen.dart';

enum AdminSection { users, merchants, drivers, analytics, finance, locations }

class AdminSectionScreen extends StatefulWidget {
  final AdminSection section;

  const AdminSectionScreen({super.key, required this.section});

  @override
  State<AdminSectionScreen> createState() => _AdminSectionScreenState();
}

class _AdminSectionScreenState extends State<AdminSectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    final provider = context.read<AdminProvider>();
    return switch (widget.section) {
      AdminSection.users || AdminSection.merchants => provider.loadUsers(),
      AdminSection.drivers => provider.loadDrivers(),
      AdminSection.analytics => Future.wait([
          context.read<AnalyticsReportProvider>().load(),
          provider.loadUsers(),
          provider.loadLocations(),
        ]).then((_) {}),
      AdminSection.finance => provider.loadFinance(),
      AdminSection.locations => _loadSettings(provider),
    };
  }

  Future<void> _loadSettings(AdminProvider provider) async {
    await provider.loadLocations();
    await provider.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, provider, child) {
            if (widget.section != AdminSection.analytics &&
                provider.isLoading &&
                !AdminSectionData.hasData(provider, widget.section)) {
              return const AppLoadingState(message: 'Loading workspace…');
            }
            if (widget.section != AdminSection.analytics &&
                provider.error != null &&
                !AdminSectionData.hasData(provider, widget.section)) {
              return AppErrorState(message: provider.error!, onRetry: _load);
            }
            return switch (widget.section) {
              AdminSection.users => AdminUsersPage(
                  provider: provider,
                  onRefresh: _load,
                ),
              AdminSection.merchants => AdminPeoplePage(
                  title: 'Merchants',
                  subtitle:
                      'Merchant accounts, payment plans and contact details',
                  users:
                      provider.users.where((user) => user.isMerchant).toList(),
                  onRefresh: _load,
                ),
              AdminSection.drivers => AdminDriversPage(
                  drivers: provider.drivers,
                  onRefresh: _load,
                ),
              AdminSection.analytics => AdvancedAnalyticsPage(
                  onRefresh: _load,
                ),
              AdminSection.finance => AdminFinancePage(
                  provider: provider,
                  onRefresh: _load,
                ),
              AdminSection.locations => AdminLocationsPage(
                  provider: provider,
                  onRefresh: _load,
                ),
            };
          },
        ),
      ),
    );
  }
}

abstract final class AdminSectionData {
  static bool hasData(AdminProvider provider, AdminSection section) {
    return switch (section) {
      AdminSection.users || AdminSection.merchants => provider.users.isNotEmpty,
      AdminSection.drivers => provider.drivers.isNotEmpty,
      AdminSection.analytics => provider.analytics != null,
      AdminSection.finance => provider.finance != null,
      AdminSection.locations => provider.locations.isNotEmpty,
    };
  }
}

class AdminPeoplePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<User> users;
  final Future<void> Function() onRefresh;

  const AdminPeoplePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.users,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(context.pagePadding),
            itemCount: users.isEmpty ? 2 : users.length + 1,
            separatorBuilder: (context, index) =>
                SizedBox(height: index == 0 ? AppSpacing.lg : AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AppPageHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => onRefresh(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                );
              }
              if (users.isEmpty) {
                return const AppSurfaceCard(
                  child: AppEmptyState(
                    title: 'No accounts found',
                    message:
                        'Accounts will appear here when they are available.',
                    icon: Icons.people_outline_rounded,
                  ),
                );
              }
              return AdminPersonCard(user: users[index - 1], wide: wide);
            },
          );
        },
      ),
    );
  }
}

class AdminPersonCard extends StatelessWidget {
  final User user;
  final bool wide;

  const AdminPersonCard({super.key, required this.user, required this.wide});

  @override
  Widget build(BuildContext context) {
    final displayName =
        user.fullName.trim().isEmpty ? user.username : user.fullName.trim();
    final avatarText =
        displayName.isEmpty ? '?' : displayName.characters.first.toUpperCase();
    final accountType = user.accountType?.trim().toUpperCase();
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: wide
          ? Row(
              children: [
                AccountAvatar(label: avatarText, role: user.role),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    flex: 2,
                    child: PersonIdentity(
                        name: displayName, username: user.username)),
                Expanded(
                  child: Text(
                    user.role.toLowerCase(),
                    style: context.textStyles.labelLarge,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    user.phone?.isNotEmpty == true ? user.phone! : 'No phone',
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyMedium,
                  ),
                ),
                if (accountType != null && accountType.isNotEmpty)
                  AccountTypeBadge(type: accountType),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccountAvatar(label: avatarText, role: user.role),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PersonIdentity(
                          name: displayName, username: user.username),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          RoleBadge(role: user.role),
                          if (accountType != null && accountType.isNotEmpty)
                            AccountTypeBadge(type: accountType),
                        ],
                      ),
                      if (user.phone?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(user.phone!, style: context.textStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class PersonIdentity extends StatelessWidget {
  final String name;
  final String username;

  const PersonIdentity({super.key, required this.name, required this.username});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleSmall),
        const SizedBox(height: 2),
        Text('@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall),
      ],
    );
  }
}

class AccountAvatar extends StatelessWidget {
  final String label;
  final String role;

  const AccountAvatar({super.key, required this.label, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role.toLowerCase()) {
      'admin' => AppColors.brand,
      'driver' => AppColors.violet,
      'merchant' => AppColors.blue,
      _ => AppColors.inkMuted,
    };
    return CircleAvatar(
      radius: 23,
      backgroundColor: color.withValues(alpha: .1),
      foregroundColor: color,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        role.toUpperCase(),
        style: context.textStyles.labelMedium,
      ),
    );
  }
}

class AccountTypeBadge extends StatelessWidget {
  final String type;

  const AccountTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final prepaid = type == 'PREPAID';
    final color = prepaid ? AppColors.teal : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Text(
        type,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class AdminDriversPage extends StatelessWidget {
  final List<DriverSummary> drivers;
  final Future<void> Function() onRefresh;

  const AdminDriversPage(
      {super.key, required this.drivers, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(context.pagePadding),
        itemCount: drivers.isEmpty ? 2 : drivers.length + 1,
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? AppSpacing.lg : AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppPageHeader(
              title: 'Drivers',
              subtitle: 'People moving orders across the delivery network',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => onRefresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            );
          }
          if (drivers.isEmpty) {
            return const AppSurfaceCard(
              child: AppEmptyState(
                title: 'No drivers found',
                message: 'Driver accounts will appear here when configured.',
                icon: Icons.local_shipping_outlined,
              ),
            );
          }
          final driver = drivers[index - 1];
          final name =
              driver.name.trim().isEmpty ? driver.username : driver.name.trim();
          return AppSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.violetSoft,
                  foregroundColor: AppColors.violet,
                  child: Icon(Icons.local_shipping_outlined),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child:
                        PersonIdentity(name: name, username: driver.username)),
                const RoleBadge(role: 'DRIVER'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminAnalyticsPage extends StatelessWidget {
  final AnalyticsOverview? analytics;
  final Future<void> Function() onRefresh;

  const AdminAnalyticsPage(
      {super.key, required this.analytics, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final data = analytics;
    if (data == null) {
      return const AppEmptyState(
          title: 'No analytics yet',
          message: 'Analytics will appear when order data is available.');
    }
    final statuses = [
      'WAREHOUSE',
      'NEW',
      'PICKED_UP',
      'DELIVERED',
      'CANCELLED',
      'PAID',
      'COLLECTED'
    ];
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
                    title: 'Analytics',
                    subtitle:
                        'Performance signals from the current order dataset',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => onRefresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppResponsiveGrid(
                    children: [
                      AppMetricCard(
                          label: 'Total orders',
                          value: '${data.totalOrders}',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.blue),
                      AppMetricCard(
                          label: 'Revenue',
                          value: formatUsd(data.totalRevenue),
                          icon: Icons.payments_outlined,
                          color: AppColors.teal),
                      AppMetricCard(
                          label: 'Orders today',
                          value: '${data.ordersToday}',
                          icon: Icons.today_outlined,
                          color: AppColors.brand),
                      AppMetricCard(
                          label: 'Active drivers',
                          value: '${data.activeDrivers}',
                          icon: Icons.local_shipping_outlined,
                          color: AppColors.violet),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                            title: 'Orders by status',
                            subtitle:
                                'Current distribution across the workflow'),
                        const SizedBox(height: AppSpacing.lg),
                        for (var index = 0;
                            index < statuses.length;
                            index++) ...[
                          AnalyticsStatusRow(
                            status: statuses[index],
                            value: index < data.statusCounts.length
                                ? data.statusCounts[index]
                                : 0,
                            total: data.totalOrders,
                          ),
                          if (index != statuses.length - 1)
                            const SizedBox(height: AppSpacing.md),
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

class AnalyticsStatusRow extends StatelessWidget {
  final String status;
  final int value;
  final int total;

  const AnalyticsStatusRow(
      {super.key,
      required this.status,
      required this.value,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final style = OrderStatusStyle.from(status);
    final progress = total == 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
            width: 118,
            child: OrderStatusBadge(status: status, showIcon: false)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              color: style.color,
              backgroundColor: style.color.withValues(alpha: .1),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
            width: 36,
            child: Text('$value',
                textAlign: TextAlign.end,
                style: context.textStyles.titleSmall)),
      ],
    );
  }
}

class AdminFinancePage extends StatelessWidget {
  final AdminProvider provider;
  final Future<void> Function() onRefresh;

  const AdminFinancePage(
      {super.key, required this.provider, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final finance = provider.finance;
    if (finance == null) {
      return const AppEmptyState(
          title: 'No finance data',
          message: 'Balances and settlements will appear here when available.');
    }
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
                    title: 'Finance',
                    subtitle: 'Outstanding balances and settlement activity',
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: 'Export finance CSV',
                        onSelected: (kind) async {
                          try {
                            final bytes =
                                await ApiService.exportFinanceCsv(kind);
                            await saveOrderCsv(
                                'GoDelivery-$kind-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
                                bytes);
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Export failed: $error')));
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'collections',
                              child: Text('Export collections')),
                          PopupMenuItem(
                              value: 'payments',
                              child: Text('Export payments')),
                          PopupMenuItem(
                              value: 'returns', child: Text('Export returns')),
                        ],
                        child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.download_outlined)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onRefresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppResponsiveGrid(
                    maxColumns: 3,
                    children: [
                      AppMetricCard(
                          label: 'Owed to merchants',
                          value: formatUsd(finance.owedToMerchants),
                          icon: Icons.storefront_outlined,
                          color: AppColors.teal),
                      AppMetricCard(
                          label: 'Owed by merchants',
                          value: formatUsd(finance.owedByMerchants),
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.amber),
                      AppMetricCard(
                          label: 'Owed by drivers',
                          value: formatUsd(finance.owedByDrivers),
                          icon: Icons.local_shipping_outlined,
                          color: AppColors.violet),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FinanceBalances(finance: finance),
                  const SizedBox(height: AppSpacing.lg),
                  AdminFinancialOperations(
                    admin: provider,
                    isAdmin:
                        context.watch<AuthProvider>().currentUser?.isAdmin ==
                            true,
                    onRefresh: onRefresh,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FinanceActivity(provider: provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceBalances extends StatelessWidget {
  final FinanceOverview finance;

  const FinanceBalances({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final merchant = BalanceList(
            title: 'Merchant balances',
            rows: finance.merchants,
            icon: Icons.storefront_outlined);
        final drivers = BalanceList(
            title: 'Driver balances',
            rows: finance.drivers,
            icon: Icons.local_shipping_outlined);
        if (constraints.maxWidth < 840) {
          return Column(children: [
            merchant,
            const SizedBox(height: AppSpacing.md),
            drivers
          ]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: merchant),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: drivers),
          ],
        );
      },
    );
  }
}

class BalanceList extends StatelessWidget {
  final String title;
  final List<FinancePartyBalance> rows;
  final IconData icon;

  const BalanceList(
      {super.key, required this.title, required this.rows, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
              title: title, subtitle: '${rows.length} open accounts'),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('No outstanding balances')),
            )
          else
            for (var index = 0; index < rows.take(8).length; index++) ...[
              BalanceRow(row: rows[index], icon: icon),
              if (index != rows.take(8).length - 1) const Divider(),
            ],
        ],
      ),
    );
  }
}

class BalanceRow extends StatelessWidget {
  final FinancePartyBalance row;
  final IconData icon;

  const BalanceRow({super.key, required this.row, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name.isEmpty ? row.username : row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleSmall),
                Text('${row.orderCount} orders',
                    style: context.textStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              formatUsd(row.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: context.textStyles.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceActivity extends StatelessWidget {
  final AdminProvider provider;

  const FinanceActivity({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final item in provider.collections.take(5))
        FinanceActivityItem(
          title: 'Collection #${item.number}',
          subtitle: '${item.driverName} · ${item.orderCount} orders',
          value: formatUsd(item.amount - item.deliveryFee),
          date: item.createdAt,
          icon: Icons.move_to_inbox_outlined,
          color: AppColors.violet,
        ),
      for (final item in provider.payments.take(5))
        FinanceActivityItem(
          title: 'Payment #${item.number}',
          subtitle: '${item.merchantName} · ${item.orderCount} orders',
          value: formatUsd(item.amount),
          date: item.createdAt,
          icon: Icons.payments_outlined,
          color: AppColors.teal,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
              title: 'Recent settlements',
              subtitle: 'Latest collections and merchant payments'),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('No settlement activity yet')),
            )
          else
            for (var index = 0; index < items.length; index++) ...[
              FinanceActivityRow(item: items[index]),
              if (index != items.length - 1) const Divider(),
            ],
        ],
      ),
    );
  }
}

class FinanceActivityItem {
  final String title;
  final String subtitle;
  final String value;
  final DateTime date;
  final IconData icon;
  final Color color;

  const FinanceActivityItem(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.date,
      required this.icon,
      required this.color});
}

class FinanceActivityRow extends StatelessWidget {
  final FinanceActivityItem item;

  const FinanceActivityRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: item.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.textStyles.titleSmall),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                Text(DateFormat('MMM d').format(item.date),
                    style: context.textStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLocationsPage extends StatelessWidget {
  final AdminProvider provider;
  final Future<void> Function() onRefresh;

  const AdminLocationsPage(
      {super.key, required this.provider, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(context.pagePadding),
        itemCount:
            provider.locations.isEmpty ? 3 : provider.locations.length + 2,
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? AppSpacing.lg : AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppPageHeader(
              title: 'Locations & settings',
              subtitle: 'District and city coverage configured by the backend',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => onRefresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            );
          }
          if (index == 1) {
            return AdminSettingsControls(provider: provider);
          }
          if (provider.locations.isEmpty) {
            return const AppSurfaceCard(
              child: AppEmptyState(
                  title: 'No locations configured',
                  message:
                      'Delivery coverage will appear here when configured.',
                  icon: Icons.map_outlined),
            );
          }
          final district = provider.locations[index - 2];
          return AppSurfaceCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              leading: const CircleAvatar(
                backgroundColor: AppColors.brandSoft,
                foregroundColor: AppColors.brandStrong,
                child: Icon(Icons.location_on_outlined),
              ),
              title:
                  Text(district.nameEn, style: context.textStyles.titleSmall),
              subtitle: Text('${district.cities.length} cities',
                  style: context.textStyles.bodySmall),
              children: [
                for (final city in district.cities)
                  ListTile(
                    minTileHeight: 48,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    leading: const Icon(Icons.circle,
                        size: 8, color: AppColors.inkSubtle),
                    title: Text(city.nameEn),
                    trailing: city.nameAr.isEmpty
                        ? null
                        : Text(city.nameAr,
                            style: context.textStyles.bodySmall),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
