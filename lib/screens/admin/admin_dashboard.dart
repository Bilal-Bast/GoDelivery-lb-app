import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../models/order.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color orange = Color(0xFFFF8A00);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  Future<void> _refresh() async {
    await context.read<OrderProvider>().fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(
              Icons.local_shipping_rounded,
              color: primaryBlue,
            ),
            SizedBox(width: 10),
            Text(
              'GoDelivery',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      drawer: _buildDrawer(context),

      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          if (provider.error != null && provider.orders.isEmpty) {
            return _buildErrorState(provider.error!);
          }

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isWide ? 28 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1200,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(provider),

                          const SizedBox(height: 24),

                          _buildStatistics(
                            provider.orders,
                            isWide,
                          ),

                          const SizedBox(height: 30),

                          _buildQuickActions(isWide),

                          const SizedBox(height: 30),

                          _buildRecentOrders(
                            provider.orders,
                            isWide,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(OrderProvider provider) {
    final totalOrders = provider.orders.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            darkBlue,
            primaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Overview of your delivery operations',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalOrders total orders',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 64,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(
    List<Order> orders,
    bool isWide,
  ) {
    final total = orders.length;

    final newOrders = orders.where((order) {
      final status = order.status.toUpperCase();
      return status == 'NEW';
    }).length;

    final pickedUp = orders.where((order) {
      final status = order.status.toUpperCase();
      return status == 'PICKED_UP' ||
          status == 'PICKED UP' ||
          status == 'PICKEDUP';
    }).length;

    final delivered = orders.where((order) {
      return _isDelivered(order.status);
    }).length;

    final cancelled = orders.where((order) {
      return _isCancelled(order.status);
    }).length;

    final revenue = orders
        .where((order) => !_isCancelled(order.status))
        .fold<double>(
          0,
          (sum, order) => sum + order.merchantAmount,
        );

    final cards = [
      _DashboardStat(
        title: 'Total Orders',
        value: '$total',
        subtitle: 'All orders',
        icon: Icons.inventory_2_rounded,
        iconColor: primaryBlue,
      ),
      _DashboardStat(
        title: 'New Orders',
        value: '$newOrders',
        subtitle: 'Waiting for pickup',
        icon: Icons.fiber_new_rounded,
        iconColor: Colors.orange,
      ),
      _DashboardStat(
        title: 'Picked Up',
        value: '$pickedUp',
        subtitle: 'In delivery process',
        icon: Icons.local_shipping_rounded,
        iconColor: Colors.deepPurple,
      ),
      _DashboardStat(
        title: 'Delivered',
        value: '$delivered',
        subtitle: 'Successfully delivered',
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      ),
      _DashboardStat(
        title: 'Cancelled',
        value: '$cancelled',
        subtitle: 'Cancelled orders',
        icon: Icons.cancel_rounded,
        iconColor: Colors.red,
      ),
      _DashboardStat(
        title: 'Revenue',
        value: _formatMoney(revenue),
        subtitle: 'Merchant amounts',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Colors.teal,
      ),
    ];

    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.65,
        ),
        itemBuilder: (context, index) {
          return _StatCard(data: cards[index]);
        },
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        return _StatCard(data: cards[index]);
      },
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 12),

        if (isWide)
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_box_rounded,
                  title: 'New Order',
                  subtitle: 'Create a new delivery',
                  color: primaryBlue,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan Order',
                  subtitle: 'Scan a barcode',
                  color: orange,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'All Orders',
                  subtitle: 'View your orders',
                  color: Colors.deepPurple,
                  onTap: () {},
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_box_rounded,
                      title: 'New Order',
                      subtitle: 'Create a new delivery',
                      color: primaryBlue,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan Order',
                      subtitle: 'Scan a barcode',
                      color: orange,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _ActionCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'All Orders',
                  subtitle: 'View your orders',
                  color: Colors.deepPurple,
                  onTap: () {},
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // RECENT ORDERS
  // ============================================================

  Widget _buildRecentOrders(
    List<Order> orders,
    bool isWide,
  ) {
    final recentOrders = [...orders]
      ..sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

    final displayedOrders = recentOrders.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View all'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (displayedOrders.isEmpty)
          _buildEmptyOrders()
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE7EBF2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < displayedOrders.length; i++) ...[
                  _OrderTile(
                    order: displayedOrders[i],
                    isWide: isWide,
                  ),
                  if (i != displayedOrders.length - 1)
                    const Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyOrders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7EBF2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders from your GoDelivery database will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final username = authProvider.currentUser?.username ?? 'Admin';

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              24,
              55,
              24,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  darkBlue,
                  primaryBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'GoDelivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  selected: true,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Orders',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.people_outline_rounded,
                  title: 'Users',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Finance',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Drivers',
                  onTap: () {},
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Divider(),
                ),

                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().logout();
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'GoDelivery Admin',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isDelivered(String status) {
    final normalized = status.toUpperCase();

    return normalized == 'DELIVERED' ||
        normalized == 'PAID' ||
        normalized == 'COLLECTED';
  }

  bool _isCancelled(String status) {
    final normalized = status.toUpperCase();

    return normalized == 'CANCELLED' ||
        normalized == 'CANCELED';
  }

  String _formatMoney(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}

// ================================================================
// STAT CARD
// ================================================================

class _DashboardStat {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _DashboardStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

class _StatCard extends StatelessWidget {
  final _DashboardStat data;

  const _StatCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: data.iconColor,
                  size: 22,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz,
                color: Colors.grey.shade400,
              ),
            ],
          ),

          const Spacer(),

          Text(
            data.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          Text(
            data.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF39445A),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACTION CARD
// ================================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE7EBF2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ORDER TILE
// ================================================================

class _OrderTile extends StatelessWidget {
  final Order order;
  final bool isWide;

  const _OrderTile({
    required this.order,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(order.status);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status.icon,
              color: status.color,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.customerName.isEmpty
                            ? 'Unknown Customer'
                            : order.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (order.isExpress) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '#${_shortId(order.id)} • ${order.city}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (isWide)
            _StatusBadge(
              label: status.label,
              color: status.color,
            ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  _StatusInfo _statusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'WAREHOUSE':
        return const _StatusInfo(
          'Warehouse',
          Colors.blueGrey,
          Icons.inventory_2_outlined,
        );

      case 'NEW':
        return const _StatusInfo(
          'New',
          Colors.orange,
          Icons.fiber_new_rounded,
        );

      case 'PICKED_UP':
      case 'PICKED UP':
      case 'PICKEDUP':
        return const _StatusInfo(
          'Picked Up',
          Colors.deepPurple,
          Icons.local_shipping_outlined,
        );

      case 'DELIVERED':
        return const _StatusInfo(
          'Delivered',
          Colors.green,
          Icons.check_circle_outline,
        );

      case 'CANCELLED':
      case 'CANCELED':
        return const _StatusInfo(
          'Cancelled',
          Colors.red,
          Icons.cancel_outlined,
        );

      case 'PAID':
        return const _StatusInfo(
          'Paid',
          Colors.teal,
          Icons.payments_outlined,
        );

      case 'COLLECTED':
        return const _StatusInfo(
          'Collected',
          Colors.indigo,
          Icons.inventory_outlined,
        );

      default:
        return _StatusInfo(
          status,
          Colors.grey.shade600,
          Icons.help_outline,
        );
    }
  }
}

// ================================================================
// STATUS BADGE
// ================================================================

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ================================================================
// DRAWER ITEM
// ================================================================

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.selected = false,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFE8F1FB)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: iconColor ??
              (selected
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF687386)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ??
                (selected
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF30394A)),
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ================================================================
// STATUS MODEL
// ================================================================

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusInfo(
    this.label,
    this.color,
    this.icon,
  );
}