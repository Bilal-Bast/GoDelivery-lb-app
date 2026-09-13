import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../models/user.dart';
import '../../models/payment.dart';
import '../../models/order.dart';
import '../../models/collection.dart';
import '../../models/district.dart';
import '../../models/city.dart';

// ==================== ORDERS LIST SCREEN ====================
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedStatus = 'ALL';
  
  final List<String> _statusFilters = [
    'ALL',
    'WAREHOUSE',
    'NEW',
    'PICKED_UP',
    'DELIVERED',
    'PAID',
    'CANCELLED',
    'COLLECTED',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final status = _selectedStatus == 'ALL' ? null : _selectedStatus;
    context.read<OrderProvider>().fetchOrders(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = status);
                      _loadOrders();
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Orders List
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, _) {
                if (orderProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (orderProvider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orderProvider.orders.length,
                    itemBuilder: (context, index) {
                      final order = orderProvider.orders[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/home/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 12)}',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Customer Info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Location Info
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.district}, ${order.city}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amount and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LBP ${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAREHOUSE':
        return Colors.blue;
      case 'NEW':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.purple;
      case 'DELIVERED':
        return AppTheme.successColor;
      case 'PAID':
        return Colors.green;
      case 'CANCELLED':
        return AppTheme.errorColor;
      case 'COLLECTED':
        return Colors.teal;
      default:
        return AppTheme.textHint;
    }
  }
}

// ==================== ORDER DETAIL SCREEN ====================
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderProvider>().fetchOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = orderProvider.selectedOrder;
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    orderProvider.error ?? 'Order not found',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(order.statusUpdatedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Info
                _buildSectionTitle(context, 'Customer Information'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Name', order.customerName),
                        const Divider(),
                        _buildInfoRow('Phone', order.customerPhone),
                        const Divider(),
                        _buildInfoRow('Location', '${order.district}, ${order.city}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Order Details
                _buildSectionTitle(context, 'Order Details'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Order ID', order.id),
                        const Divider(),
                        _buildInfoRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)),
                        const Divider(),
                        _buildInfoRow('Express', order.isExpress ? 'Yes' : 'No'),
                        if (order.expressNote.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow('Note', order.expressNote),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pricing
                _buildSectionTitle(context, 'Pricing'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Total', 'LBP ${order.total.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildInfoRow('Delivery Charge', 'LBP ${order.deliveryCharge.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildInfoRow(
                          'Merchant Amount',
                          'LBP ${order.merchantAmount.toStringAsFixed(2)}',
                          valueStyle: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                if (order.isPending)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _showUpdateStatusDialog(context, order),
                      child: const Text('Update Status'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textLight),
        ),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAREHOUSE':
        return Colors.blue;
      case 'NEW':
        return Colors.orange;
      case 'Picked_up':
        return Colors.purple;
      case 'DELIVERED':
        return AppTheme.successColor;
      case 'Paid':
        return AppTheme.successColor;
      case 'Canceled':
        return AppTheme.errorColor;
      case 'COLLECTED':
        return Colors.green;
      default:
        return AppTheme.textHint;
    }
  }

  void _showUpdateStatusDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: const Text('What would you like to change the status to?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<OrderProvider>().updateOrderStatus(order.id, 'Delivered');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Status updated successfully')),
              );
            },
            child: const Text('Mark as Delivered'),
          ),
        ],
      ),
    );
  }
}