import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_models.dart';
import '../../providers/providers.dart';

enum AdminSection { users, drivers, analytics, finance, locations }

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
      AdminSection.users => provider.loadUsers(),
      AdminSection.drivers => provider.loadDrivers(),
      AdminSection.analytics => provider.loadAnalytics(),
      AdminSection.finance => provider.loadFinance(),
      AdminSection.locations => provider.loadLocations(),
    };
  }

  String get _title => switch (widget.section) {
        AdminSection.users => 'Users',
        AdminSection.drivers => 'Drivers',
        AdminSection.analytics => 'Analytics',
        AdminSection.finance => 'Finance',
        AdminSection.locations => 'Locations & Settings',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _ErrorState(message: provider.error!, onRetry: _load);
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: switch (widget.section) {
              AdminSection.users => _users(provider),
              AdminSection.drivers => _drivers(provider),
              AdminSection.analytics => _analytics(provider),
              AdminSection.finance => _finance(provider),
              AdminSection.locations => _locations(provider),
            },
          );
        },
      ),
    );
  }

  Widget _users(AdminProvider provider) {
    if (provider.users.isEmpty) return const _EmptyState('No users found');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = provider.users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
                child: Text(user.username.substring(0, 1).toUpperCase())),
            title: Text(
                user.fullName.trim().isEmpty ? user.username : user.fullName),
            subtitle: Text('${user.username} · ${user.role.toLowerCase()}'),
            trailing: user.accountType == null
                ? null
                : Chip(label: Text(user.accountType!.toLowerCase())),
          ),
        );
      },
    );
  }

  Widget _drivers(AdminProvider provider) {
    if (provider.drivers.isEmpty) return const _EmptyState('No drivers found');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.drivers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final driver = provider.drivers[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
            title: Text(driver.name),
            subtitle: Text(driver.username),
          ),
        );
      },
    );
  }

  Widget _analytics(AdminProvider provider) {
    final data = provider.analytics;
    if (data == null) return const _EmptyState('No analytics available');
    final counts = data.statusCounts;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metricGrid([
          ('Total orders', '${data.totalOrders}', Icons.inventory_2),
          ('Revenue', _money(data.totalRevenue), Icons.payments),
          ('Orders today', '${data.ordersToday}', Icons.today),
          ('Active drivers', '${data.activeDrivers}', Icons.local_shipping),
        ]),
        const SizedBox(height: 24),
        Text('Orders by status', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (var i = 0; i < _statusNames.length; i++)
          ListTile(
            dense: true,
            title: Text(_statusNames[i]),
            trailing: Text(i < counts.length ? '${counts[i]}' : '0'),
          ),
      ],
    );
  }

  Widget _finance(AdminProvider provider) {
    final data = provider.finance;
    if (data == null) return const _EmptyState('No finance data available');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metricGrid([
          ('Owed to merchants', _money(data.owedToMerchants), Icons.storefront),
          (
            'Owed by merchants',
            _money(data.owedByMerchants),
            Icons.receipt_long
          ),
          ('Owed by drivers', _money(data.owedByDrivers), Icons.local_shipping),
          (
            'Settlement records',
            '${provider.collections.length + provider.payments.length}',
            Icons.account_balance
          ),
        ]),
        const SizedBox(height: 24),
        _balanceSection('Merchant balances', data.merchants),
        const SizedBox(height: 20),
        _balanceSection('Driver balances', data.drivers),
        const SizedBox(height: 20),
        Text('Recent collections',
            style: Theme.of(context).textTheme.titleLarge),
        for (final item in provider.collections.take(10))
          ListTile(
            title: Text('#${item.number} · ${item.driverName}'),
            subtitle: Text('${item.orderCount} orders'),
            trailing: Text(_money(item.amount - item.deliveryFee)),
          ),
        const SizedBox(height: 20),
        Text('Recent merchant payments',
            style: Theme.of(context).textTheme.titleLarge),
        for (final item in provider.payments.take(10))
          ListTile(
            title: Text('#${item.number} · ${item.merchantName}'),
            subtitle: Text(
                '${item.orderCount} orders${item.isAdvance ? ' · advance' : ''}'),
            trailing: Text(_money(item.amount)),
          ),
      ],
    );
  }

  Widget _balanceSection(String title, List<FinancePartyBalance> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (rows.isEmpty) const ListTile(title: Text('No outstanding balance')),
        for (final row in rows)
          ListTile(
            title: Text(row.name.isEmpty ? row.username : row.name),
            subtitle: Text(
                '${row.orderCount} orders${row.accountType == null ? '' : ' · ${row.accountType}'}'),
            trailing: Text(_money(row.balance)),
          ),
      ],
    );
  }

  Widget _locations(AdminProvider provider) {
    if (provider.locations.isEmpty) {
      return const _EmptyState('No locations configured');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.locations.length,
      itemBuilder: (context, index) {
        final district = provider.locations[index];
        return Card(
          child: ExpansionTile(
            title: Text(district.nameEn),
            subtitle: Text('${district.cities.length} cities'),
            children: [
              for (final city in district.cities)
                ListTile(
                  dense: true,
                  title: Text(city.nameEn),
                  subtitle: city.nameAr.isEmpty ? null : Text(city.nameAr),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricGrid(List<(String, String, IconData)> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            for (final item in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$3, color: Colors.blue.shade700),
                      const SizedBox(height: 10),
                      Text(item.$2,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(item.$1, maxLines: 2),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

const _statusNames = [
  'Warehouse',
  'New',
  'Picked up',
  'Delivered',
  'Cancelled',
  'Paid',
  'Collected',
];

String _money(double value) => 'LBP ${value.toStringAsFixed(0)}';

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          const Icon(Icons.inbox_outlined, size: 48),
          const SizedBox(height: 12),
          Center(child: Text(message)),
        ],
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
