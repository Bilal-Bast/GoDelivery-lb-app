import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../widgets/app_components.dart';
import '../../widgets/godelivery_logo.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.medium;
        return Scaffold(
          appBar: MarketplaceAppBar(compact: compact),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AppContent(
                    maxWidth: 1240,
                    padding: EdgeInsets.fromLTRB(
                      context.pagePadding,
                      AppSpacing.md,
                      context.pagePadding,
                      compact ? 104 : AppSpacing.xxl,
                    ),
                    child: const MarketplaceContent(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: compact ? const MarketplaceNavigation() : null,
        );
      },
    );
  }
}

class MarketplaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool compact;

  const MarketplaceAppBar({super.key, required this.compact});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const GoDeliveryLogo(height: 36),
      actions: [
        if (!compact)
          TextButton(onPressed: () {}, child: const Text('Browse stores')),
        IconButton(
          tooltip: 'Cart',
          onPressed: () {},
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
        if (compact)
          IconButton(
            tooltip: 'Login',
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.person_outline_rounded),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Tooltip(
              message: 'Login',
              child: FilledButton.tonalIcon(
                key: const Key('marketplace_login_button'),
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign in'),
              ),
            ),
          ),
      ],
    );
  }
}

class MarketplaceContent extends StatelessWidget {
  const MarketplaceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MarketplaceHero(),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Shop by category',
          subtitle: 'Find what you need from local businesses',
        ),
        const SizedBox(height: AppSpacing.md),
        const MarketplaceCategories(),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(
          title: 'Featured stores',
          subtitle: 'Popular local partners near you',
          trailing: TextButton(onPressed: () {}, child: const Text('See all')),
        ),
        const SizedBox(height: AppSpacing.md),
        const FeaturedStores(),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(
          title: 'Popular right now',
          subtitle: 'Frequently ordered products',
          trailing: TextButton(onPressed: () {}, child: const Text('See all')),
        ),
        const SizedBox(height: AppSpacing.md),
        const PopularProducts(),
      ],
    );
  }
}

class MarketplaceHero extends StatelessWidget {
  const MarketplaceHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.raised,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          if (!wide) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  MarketplaceHeroCopy(),
                  SizedBox(height: AppSpacing.lg),
                  MarketplaceHeroVisual(compact: true),
                ],
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Expanded(flex: 3, child: MarketplaceHeroCopy()),
                SizedBox(width: AppSpacing.xl),
                Expanded(flex: 2, child: MarketplaceHeroVisual()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MarketplaceHeroCopy extends StatelessWidget {
  const MarketplaceHeroCopy({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Text(
            'DELIVERED ACROSS LEBANON',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Local favorites,\ndelivered with care.',
          style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Discover restaurants, groceries, pharmacies and shops from around your neighborhood.',
          style: TextStyle(
              color: AppColors.onDarkMuted, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('marketplace_search_field'),
          decoration: InputDecoration(
            hintText: 'Search products or stores',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Use my location',
              onPressed: () {},
              icon: const Icon(Icons.my_location_rounded),
            ),
          ),
        ),
      ],
    );
  }
}

class MarketplaceHeroVisual extends StatelessWidget {
  final bool compact;

  const MarketplaceHeroVisual({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GoDelivery delivery illustration',
      child: SizedBox(
        height: compact ? 150 : 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: compact ? 150 : 220,
              height: compact ? 150 : 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
                border: Border.all(
                    color: Colors.white.withValues(alpha: .08), width: 22),
              ),
            ),
            Container(
              width: compact ? 94 : 132,
              height: compact ? 94 : 132,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.darkShadow,
                      blurRadius: 30,
                      offset: Offset(0, 14)),
                ],
              ),
              child: Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: compact ? 48 : 68),
            ),
            Positioned(
              top: compact ? 8 : 20,
              right: compact ? 26 : 36,
              child: const HeroMiniBadge(
                  icon: Icons.schedule_rounded, label: 'Fast'),
            ),
            Positioned(
              bottom: compact ? 6 : 22,
              left: compact ? 16 : 24,
              child: const HeroMiniBadge(
                  icon: Icons.favorite_rounded, label: 'Local'),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroMiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const HeroMiniBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.subtle),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.brand, size: 16),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class MarketplaceCategories extends StatelessWidget {
  const MarketplaceCategories({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = [
      MarketplaceCategory('Food', Icons.restaurant_rounded, AppColors.brand),
      MarketplaceCategory(
          'Grocery', Icons.shopping_basket_rounded, AppColors.teal),
      MarketplaceCategory(
          'Health', Icons.local_pharmacy_rounded, AppColors.red),
      MarketplaceCategory('Fashion', Icons.checkroom_rounded, AppColors.violet),
      MarketplaceCategory('Electronics', Icons.devices_rounded, AppColors.blue),
    ];
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) =>
            CategoryCard(category: categories[index]),
      ),
    );
  }
}

class MarketplaceCategory {
  final String label;
  final IconData icon;
  final Color color;

  const MarketplaceCategory(this.label, this.icon, this.color);
}

class CategoryCard extends StatelessWidget {
  final MarketplaceCategory category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.outlineVariant)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: category.color, size: 28),
                const SizedBox(height: AppSpacing.xs),
                Text(category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedStores extends StatelessWidget {
  const FeaturedStores({super.key});

  @override
  Widget build(BuildContext context) {
    const stores = [
      StoreInfo('GoFood', 'Meals & drinks', Icons.restaurant_rounded,
          AppColors.brand),
      StoreInfo('GoMarket', 'Fresh groceries', Icons.shopping_cart_rounded,
          AppColors.teal),
      StoreInfo('GoTech', 'Electronics', Icons.devices_rounded, AppColors.blue),
    ];
    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => StoreCard(info: stores[index]),
      ),
    );
  }
}

class StoreInfo {
  final String name;
  final String category;
  final IconData icon;
  final Color color;

  const StoreInfo(this.name, this.category, this.icon, this.color);
}

class StoreCard extends StatelessWidget {
  final StoreInfo info;

  const StoreCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                  color: info.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(info.icon, color: info.color, size: 30),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.name, style: context.textStyles.titleMedium),
                  const SizedBox(height: 3),
                  Text(info.category, style: context.textStyles.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  const Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: AppColors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('4.8',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Text('20–35 min',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.inkMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PopularProducts extends StatelessWidget {
  const PopularProducts({super.key});

  @override
  Widget build(BuildContext context) {
    const products = [
      ProductInfo('Fresh Burger', '\$8.50', Icons.lunch_dining_rounded,
          AppColors.brand),
      ProductInfo('Fresh Groceries', '\$12.00', Icons.shopping_basket_rounded,
          AppColors.teal),
      ProductInfo('Wireless Headphones', '\$29.99', Icons.headphones_rounded,
          AppColors.blue),
      ProductInfo('Running Shoes', '\$45.00', Icons.directions_run_rounded,
          AppColors.violet),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          >= 1080 => 4,
          >= 700 => 3,
          _ => 2,
        };
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: constraints.maxWidth < 500 ? 220 : 242,
          ),
          itemBuilder: (context, index) => ProductCard(info: products[index]),
        );
      },
    );
  }
}

class ProductInfo {
  final String name;
  final String price;
  final IconData icon;
  final Color color;

  const ProductInfo(this.name, this.price, this.icon, this.color);
}

class ProductCard extends StatelessWidget {
  final ProductInfo info;

  const ProductCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: info.color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(info.icon, size: 52, color: info.color),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(info.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Expanded(
                  child: Text(info.price,
                      style: context.textStyles.titleMedium
                          ?.copyWith(color: AppColors.brandStrong))),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: AppColors.brandSoft, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.brandStrong, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MarketplaceNavigation extends StatelessWidget {
  const MarketplaceNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 3) context.go('/login');
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search'),
        NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Cart'),
        NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account'),
      ],
    );
  }
}
