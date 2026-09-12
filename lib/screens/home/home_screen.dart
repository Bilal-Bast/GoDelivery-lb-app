import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user?.isMerchant ?? false) {
      context.read<OrderProvider>().fetchOrders();
      context.read<MerchantProvider>().fetchBalance();
    } else if (user?.isDriver ?? false) {
      context.read<DriverProvider>().fetchDriverOrders();
      context.read<DriverProvider>().fetchCollections();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GoDelivery'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: user?.isMerchant ?? false
            ? _buildMerchantHome()
            : user?.isDriver ?? false
                ? _buildDriverHome()
                : _buildAdminHome(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: 'Home',
            ),
            if (user?.isMerchant ?? false)
              BottomNavigationBarItem(
                icon: const Icon(Icons.add_box),
                label: 'Create',
              ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: (index) {
            setState(() => _currentIndex = index);
            _handleNavigation(index, user?.role ?? '');
          },
        ),
      ),
    );
  }

  Widget _buildMerchantHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Consumer<MerchantProvider>(
            builder: (context, merchantProvider, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LBP ${merchantProvider.balance.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Owed: LBP ${merchantProvider.totalOwed.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent Orders
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              if (orderProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (orderProvider.orders.isEmpty) {
                return Center(
                  child: Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderProvider.orders.take(5).length,
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  return _buildOrderCard(context, order);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Orders',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Consumer<DriverProvider>(
                          builder: (context, driverProvider, _) {
                            return Text(
                              '${driverProvider.driverOrders.length}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Collections',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Consumer<DriverProvider>(
                          builder: (context, driverProvider, _) {
                            return Text(
                              '${driverProvider.collections.length}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Assigned Orders
          Text(
            'Assigned Orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Consumer<DriverProvider>(
            builder: (context, driverProvider, _) {
              if (driverProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (driverProvider.driverOrders.isEmpty) {
                return Center(
                  child: Text(
                    'No assigned orders',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: driverProvider.driverOrders.take(5).length,
                itemBuilder: (context, index) {
                  final order = driverProvider.driverOrders[index];
                  return _buildOrderCard(context, order);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHome() {
    return Center(
      child: Text(
        'Admin Dashboard',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Order #${order.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerName}'),
            Text('Amount: LBP ${order.total}'),
            Text('Status: ${order.status}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor),
        onTap: () => context.push('/home/orders/${order.id}'),
      ),
    );
  }

  void _handleNavigation(int index, String role) {
    if (role == 'MERCHANT') {
      if (index == 1) {
        context.push('/home/create-order');
      } else if (index == 2) {
        context.push('/home/profile');
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}