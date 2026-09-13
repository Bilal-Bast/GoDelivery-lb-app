import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/order.dart';

// ==================== ORDERS LIST SCREEN ====================

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'ALL';
  String _searchQuery = '';

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
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _loadOrders() {
    final status =
        _selectedStatus == 'ALL' ? null : _selectedStatus;

    context.read<OrderProvider>().fetchOrders(status: status);
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_searchQuery.isEmpty) {
      return orders;
    }

    return orders.where((order) {
      final values = [
        order.id,
        order.customerName,
        order.customerPhone,
        order.merchantId,
        order.city,
        order.district,
      ].map((value) => value.toLowerCase());

      return values.any(
        (value) => value.contains(_searchQuery),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  if (orderProvider.isLoading &&
                      orderProvider.orders.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (orderProvider.error != null &&
                      orderProvider.orders.isEmpty) {
                    return _buildErrorState(
                      orderProvider.error!,
                    );
                  }

                  final orders =
                      _getFilteredOrders(orderProvider.orders);

                  if (orders.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadOrders();
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= 900;

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 24 : 12,
                            vertical: 12,
                          ),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(
                              context,
                              orders[index],
                              isWide,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Search order ID, customer, phone, merchant...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 12),

          // Status Filters
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final selected = _selectedStatus == status;

                return FilterChip(
                  label: Text(_displayStatus(status)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = status;
                    });

                    _loadOrders();
                  },
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Order order,
    bool isWide,
  ) {
    final statusColor = _getStatusColor(order.status);

    final shortId = order.id.length > 12
        ? order.id.substring(0, 12)
        : order.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push('/home/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isWide
              ? _buildWideOrderCard(
                  order,
                  shortId,
                  statusColor,
                )
              : _buildMobileOrderCard(
                  order,
                  shortId,
                  statusColor,
                ),
        ),
      ),
    );
  }

  Widget _buildMobileOrderCard(
    Order order,
    String shortId,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Order #$shortId',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusBadge(
              order.status,
              statusColor,
            ),
          ],
        ),

        const SizedBox(height: 14),

        _buildInfoLine(
          Icons.person_outline,
          order.customerName.isEmpty
              ? 'Unknown customer'
              : order.customerName,
        ),

        const SizedBox(height: 7),

        _buildInfoLine(
          Icons.phone_outlined,
          order.customerPhone,
        ),

        const SizedBox(height: 7),

        _buildInfoLine(
          Icons.location_on_outlined,
          '${order.district}, ${order.city}',
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LBP ${_formatAmount(order.total)}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              DateFormat('MMM dd, HH:mm')
                  .format(order.createdAt),
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),

        if (order.isExpress) ...[
          const SizedBox(height: 10),
          _buildExpressBadge(),
        ],
      ],
    );
  }

  Widget _buildWideOrderCard(
    Order order,
    String shortId,
    Color statusColor,
  ) {
    return Row(
      children: [
        // Order
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Order #$shortId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('MMM dd, yyyy • HH:mm')
                    .format(order.createdAt),
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Customer
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                order.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                order.customerPhone,
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Location
        Expanded(
          flex: 2,
          child: Text(
            '${order.district}, ${order.city}',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Amount
        Expanded(
          flex: 1,
          child: Text(
            'LBP ${_formatAmount(order.total)}',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),

        const SizedBox(width: 16),

        // Status
        _buildStatusBadge(
          order.status,
          statusColor,
        ),

        const SizedBox(width: 8),

        const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildInfoLine(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: AppTheme.textHint,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    String status,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExpressBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 15,
            color: Colors.orange,
          ),
          SizedBox(width: 4),
          Text(
            'EXPRESS',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 70,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search.'
                : 'There are no orders in this filter.',
            style: TextStyle(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'PICKED_UP':
        return 'Picked Up';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.##').format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAREHOUSE':
        return Colors.blue;
      case 'NEW':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.deepPurple;
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

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() =>
      _OrderDetailScreenState();
}

class _OrderDetailScreenState
    extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<OrderProvider>()
          .fetchOrder(widget.orderId);
    });
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final order = orderProvider.selectedOrder;

          if (order == null) {
            return _buildErrorState(
              orderProvider.error ?? 'Order not found',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(order),
                    const SizedBox(height: 16),

                    _buildSectionTitle(
                      context,
                      'Customer Information',
                    ),
                    _buildCustomerCard(order),

                    const SizedBox(height: 16),

                    _buildSectionTitle(
                      context,
                      'Order Details',
                    ),
                    _buildOrderDetailsCard(order),

                    const SizedBox(height: 16),

                    _buildSectionTitle(
                      context,
                      'Pricing',
                    ),
                    _buildPricingCard(order),

                    const SizedBox(height: 20),

                    if (order.isPending)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showUpdateStatusDialog(
                            context,
                            order,
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                          label:
                              const Text('Update Status'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    final color = _getStatusColor(order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayStatus(order.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                const Text(
                  'Updated',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'MMM dd, HH:mm',
                  ).format(order.statusUpdatedAt),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              'Name',
              order.customerName,
            ),
            const Divider(),
            _buildInfoRow(
              'Phone',
              order.customerPhone,
            ),
            const Divider(),
            _buildInfoRow(
              'District',
              order.district,
            ),
            const Divider(),
            _buildInfoRow(
              'City',
              order.city,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Order ID', order.id),
            const Divider(),
            _buildInfoRow(
              'Merchant',
              order.merchantId,
            ),
            const Divider(),
            _buildInfoRow(
              'Driver',
              order.driverId ?? 'Not assigned',
            ),
            const Divider(),
            _buildInfoRow(
              'Created',
              DateFormat(
                'MMM dd, yyyy HH:mm',
              ).format(order.createdAt),
            ),
            const Divider(),
            _buildInfoRow(
              'Express',
              order.isExpress ? 'Yes' : 'No',
            ),
            if (order.expressNote.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(
                'Express Note',
                order.expressNote,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              'Total',
              'LBP ${_formatAmount(order.total)}',
            ),
            const Divider(),
            _buildInfoRow(
              'Delivery Charge',
              'LBP ${_formatAmount(order.deliveryCharge)}',
            ),
            const Divider(),
            _buildInfoRow(
              'Merchant Amount',
              'LBP ${_formatAmount(order.merchantAmount)}',
              valueStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style:
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(
    BuildContext context,
    Order order,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Status'),
          content: const Text(
            'Mark this order as delivered?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final success = await context
                    .read<OrderProvider>()
                    .updateOrderStatus(
                      order.id,
                      'Delivered',
                    );

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Order marked as delivered'
                          : context
                                  .read<OrderProvider>()
                                  .error ??
                              'Failed to update order',
                    ),
                    backgroundColor: success
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                );
              },
              child: const Text('Delivered'),
            ),
          ],
        );
      },
    );
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'PICKED_UP':
        return 'Picked Up';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.##').format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAREHOUSE':
        return Colors.blue;
      case 'NEW':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.deepPurple;
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