import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../providers/providers.dart';

// ==================== DRIVER ORDERS SCREEN ====================
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
    context.read<DriverProvider>().fetchDriverOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Column(
        children: [
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['ALL', 'NEW', 'PICKED_UP', 'DELIVERED'].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = status);
                      final filterStatus = status == 'ALL' ? null : status;
                      context
                          .read<DriverProvider>()
                          .fetchDriverOrders(status: filterStatus);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Orders List
          Expanded(
            child: Consumer<DriverProvider>(
              builder: (context, driverProvider, _) {
                if (driverProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (driverProvider.error != null &&
                    driverProvider.driverOrders.isEmpty) {
                  return _ApiErrorState(
                    message: driverProvider.error!,
                    onRetry: () => driverProvider.fetchDriverOrders(
                      status: _selectedStatus == 'ALL' ? null : _selectedStatus,
                    ),
                  );
                }

                if (driverProvider.driverOrders.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders assigned',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: driverProvider.driverOrders.length,
                  itemBuilder: (context, index) {
                    final order = driverProvider.driverOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(_initialFor(order.customerFirstName)),
                        ),
                        title: Text(order.customerName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${order.district}, ${order.city}'),
                            Text('LBP ${order.total}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DRIVER COLLECTIONS SCREEN ====================
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
    context.read<DriverProvider>().fetchCollections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, _) {
          if (driverProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (driverProvider.error != null &&
              driverProvider.collections.isEmpty) {
            return _ApiErrorState(
              message: driverProvider.error!,
              onRetry: driverProvider.fetchCollections,
            );
          }

          if (driverProvider.collections.isEmpty) {
            return Center(
              child: Text(
                'No collections yet',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: driverProvider.collections.length,
            itemBuilder: (context, index) {
              final collection = driverProvider.collections[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Collection #${_shortId(collection.id)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(collection.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount Collected',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'LBP ${collection.amount.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Your Commission',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'LBP ${collection.deliveryFee.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================== MERCHANT BALANCE SCREEN ====================
class MerchantBalanceScreen extends StatefulWidget {
  const MerchantBalanceScreen({super.key});

  @override
  State<MerchantBalanceScreen> createState() => _MerchantBalanceScreenState();
}

class _MerchantBalanceScreenState extends State<MerchantBalanceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MerchantProvider>().fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Balance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<MerchantProvider>(
              builder: (context, merchantProvider, _) {
                if (merchantProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (merchantProvider.error != null) {
                  return _ApiErrorState(
                    message: merchantProvider.error!,
                    onRetry: merchantProvider.fetchBalance,
                  );
                }

                return Column(
                  children: [
                    // Total Balance Card
                    Card(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Balance',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'LBP ${merchantProvider.balance.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balance Details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Total Owed',
                              'LBP ${merchantProvider.totalOwed.toStringAsFixed(2)}',
                              AppTheme.errorColor,
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Entitled (Pending)',
                              'LBP ${merchantProvider.balance.toStringAsFixed(2)}',
                              AppTheme.successColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLight)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ==================== MERCHANT PAYMENTS SCREEN ====================
class MerchantPaymentsScreen extends StatefulWidget {
  const MerchantPaymentsScreen({super.key});

  @override
  State<MerchantPaymentsScreen> createState() => _MerchantPaymentsScreenState();
}

class _MerchantPaymentsScreenState extends State<MerchantPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MerchantProvider>().fetchPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: Consumer<MerchantProvider>(
        builder: (context, merchantProvider, _) {
          if (merchantProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (merchantProvider.error != null &&
              merchantProvider.payments.isEmpty) {
            return _ApiErrorState(
              message: merchantProvider.error!,
              onRetry: merchantProvider.fetchPayments,
            );
          }

          if (merchantProvider.payments.isEmpty) {
            return Center(
              child: Text(
                'No payments yet',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: merchantProvider.payments.length,
            itemBuilder: (context, index) {
              final payment = merchantProvider.payments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment #${_shortId(payment.id)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(payment.status)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payment.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(payment.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm')
                            .format(payment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: LBP ${payment.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (payment.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${payment.notes}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Picked_up':
        return Colors.orange;
      case 'DELIVERED':
        return AppTheme.successColor;
      case 'CANCELLED':
        return AppTheme.errorColor;
      default:
        return AppTheme.textHint;
    }
  }
}

// ==================== PROFILE SCREEN ====================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Text(
          'Profile Screen - Coming Soon',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Text(
          'Settings Screen - Coming Soon',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

String _shortId(String value) {
  return value.length <= 8 ? value : value.substring(0, 8);
}

class _ApiErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ApiErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
