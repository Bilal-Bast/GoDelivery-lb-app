import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'GoDelivery',
              style: TextStyle(
                color: Color(0xFF004E89),
                fontWeight: FontWeight.w800,
                fontSize: 21,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () {},
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF1A1A1A),
            ),
          ),
          IconButton(
            tooltip: 'Login',
            onPressed: () => context.go('/login'),
            icon: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              const Text(
                'Everything you need,',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Text(
                'delivered to your door 🚚',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B35),
                ),
              ),

              const SizedBox(height: 20),

              // Search
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(
                      Icons.search_rounded,
                      color: Color(0xFF999999),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Search products or stores...',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Categories
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 105,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _Category(
                      icon: Icons.restaurant_rounded,
                      title: 'Food',
                    ),
                    _Category(
                      icon: Icons.shopping_basket_rounded,
                      title: 'Grocery',
                    ),
                    _Category(
                      icon: Icons.local_pharmacy_rounded,
                      title: 'Health',
                    ),
                    _Category(
                      icon: Icons.checkroom_rounded,
                      title: 'Fashion',
                    ),
                    _Category(
                      icon: Icons.devices_rounded,
                      title: 'Electronics',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Featured stores
              _SectionHeader(
                title: 'Featured Stores',
                onSeeAll: () {},
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 155,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _StoreCard(
                      name: 'GoFood',
                      subtitle: 'Meals & Drinks',
                      icon: Icons.restaurant_rounded,
                    ),
                    _StoreCard(
                      name: 'GoMarket',
                      subtitle: 'Groceries',
                      icon: Icons.shopping_cart_rounded,
                    ),
                    _StoreCard(
                      name: 'GoTech',
                      subtitle: 'Electronics',
                      icon: Icons.devices_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Popular products
              _SectionHeader(
                title: 'Popular Products',
                onSeeAll: () {},
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
                children: const [
                  _ProductCard(
                    name: 'Fresh Burger',
                    price: '\$8.50',
                    icon: Icons.lunch_dining_rounded,
                  ),
                  _ProductCard(
                    name: 'Fresh Groceries',
                    price: '\$12.00',
                    icon: Icons.shopping_basket_rounded,
                  ),
                  _ProductCard(
                    name: 'Wireless Headphones',
                    price: '\$29.99',
                    icon: Icons.headphones_rounded,
                  ),
                  _ProductCard(
                    name: 'Running Shoes',
                    price: '\$45.00',
                    icon: Icons.directions_run_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        elevation: 8,
        onDestinationSelected: (index) {
          if (index == 1) {
            // Search — we'll implement this later.
          } else if (index == 2) {
            // Cart — we'll implement this later.
          } else if (index == 3) {
            context.go('/login');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Category({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Color(0xFFFF6B35),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(
              color: Color(0xFFFF6B35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;

  const _StoreCard({
    required this.name,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF004E89).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF004E89),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF39C12),
                      size: 15,
                    ),
                    SizedBox(width: 3),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final IconData icon;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 55,
                color: const Color(0xFF004E89),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
