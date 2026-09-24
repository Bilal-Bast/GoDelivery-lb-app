import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_tokens.dart';
import '../models/user.dart';
import '../providers/providers.dart';
import 'godelivery_logo.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final destinations = AppDestination.forUser(user);

    return PopScope(
      canPop: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppBreakpoints.expanded) {
            return Scaffold(
              body: Row(
                children: [
                  ExpandedNavigationPanel(
                    user: user,
                    destinations: destinations,
                    location: location,
                  ),
                  VerticalDivider(
                    width: 1,
                    color: context.colors.outlineVariant,
                  ),
                  Expanded(child: child),
                ],
              ),
            );
          }

          if (constraints.maxWidth >= AppBreakpoints.medium) {
            return Scaffold(
              body: Row(
                children: [
                  CompactNavigationRail(
                    user: user,
                    destinations: destinations,
                    location: location,
                  ),
                  VerticalDivider(
                    width: 1,
                    color: context.colors.outlineVariant,
                  ),
                  Expanded(child: child),
                ],
              ),
            );
          }

          return Scaffold(
            body: child,
            bottomNavigationBar: MobileRoleNavigation(
              destinations: destinations,
              location: location,
            ),
          );
        },
      ),
    );
  }
}

class AppDestination {
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final List<String> matchingPrefixes;

  const AppDestination({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    this.matchingPrefixes = const [],
  });

  bool matches(String location) {
    if (path == '/home') return location == path;
    return location == path ||
        matchingPrefixes.any((prefix) => location.startsWith(prefix));
  }

  static List<AppDestination> forUser(User? user) {
    if (user?.isDriver ?? false) {
      return const [
        AppDestination(
          label: 'Deliveries',
          path: '/home/driver-orders',
          icon: Icons.route_outlined,
          selectedIcon: Icons.route_rounded,
        ),
        AppDestination(
          label: 'Collections',
          path: '/home/driver-collections',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
        ),
        AppDestination(
          label: 'Profile',
          path: '/home/profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];
    }

    if (user?.isMerchant ?? false) {
      return const [
        AppDestination(
          label: 'Overview',
          path: '/home/merchant-balance',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        AppDestination(
          label: 'Orders',
          path: '/home/orders',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2_rounded,
          matchingPrefixes: ['/home/orders/'],
        ),
        AppDestination(
          label: 'New order',
          path: '/home/create-order',
          icon: Icons.add_box_outlined,
          selectedIcon: Icons.add_box_rounded,
        ),
        AppDestination(
          label: 'Payments',
          path: '/home/merchant-payments',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
        ),
        AppDestination(
          label: 'Profile',
          path: '/home/profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];
    }

    return const [
      AppDestination(
        label: 'Overview',
        path: '/home',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      AppDestination(
        label: 'Orders',
        path: '/home/orders',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        matchingPrefixes: ['/home/orders/', '/home/create-order'],
      ),
      AppDestination(
        label: 'Drivers',
        path: '/home/admin/drivers',
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping_rounded,
      ),
      AppDestination(
        label: 'Merchants',
        path: '/home/admin/merchants',
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
      ),
      AppDestination(
        label: 'Finance',
        path: '/home/admin/finance',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
      ),
      AppDestination(
        label: 'Analytics',
        path: '/home/admin/analytics',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
      ),
      AppDestination(
        label: 'Settings',
        path: '/home/admin/locations',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ];
  }
}

class ExpandedNavigationPanel extends StatelessWidget {
  final User? user;
  final List<AppDestination> destinations;
  final String location;

  const ExpandedNavigationPanel({
    super.key,
    required this.user,
    required this.destinations,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 264,
      child: ColoredBox(
        color: context.colors.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GoDeliveryLogo(height: 38),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: ListView.separated(
                    itemCount: destinations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.xxs),
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      return ShellNavigationTile(
                        destination: destination,
                        selected: destination.matches(location),
                      );
                    },
                  ),
                ),
                UserNavigationCard(user: user),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShellNavigationTile extends StatelessWidget {
  final AppDestination destination;
  final bool selected;

  const ShellNavigationTile({
    super.key,
    required this.destination,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: Key('shell_${destination.label.toLowerCase()}_navigation'),
        onTap: () => context.go(destination.path),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 13,
          ),
          child: Row(
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: selected
                    ? AppColors.brandStrong
                    : context.colors.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  destination.label,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.brandStrong
                        : context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserNavigationCard extends StatelessWidget {
  final User? user;

  const UserNavigationCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : user?.username ?? 'Account';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brandSoft,
            foregroundColor: AppColors.brandStrong,
            child: Text(
              displayName.isEmpty
                  ? '?'
                  : displayName.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelLarge,
                ),
                Text(
                  user?.role.toLowerCase() ?? '',
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('shell_logout_button'),
            tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class CompactNavigationRail extends StatelessWidget {
  final User? user;
  final List<AppDestination> destinations;
  final String location;

  const CompactNavigationRail({
    super.key,
    required this.user,
    required this.destinations,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        destinations.indexWhere((item) => item.matches(location));
    return SafeArea(
      child: NavigationRail(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (index) => context.go(destinations[index].path),
        labelType: NavigationRailLabelType.all,
        scrollable: true,
        leading: const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: GoDeliveryLogo(height: 30),
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
        destinations: [
          for (final destination in destinations)
            NavigationRailDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: Text(destination.label),
            ),
        ],
      ),
    );
  }
}

class MobileRoleNavigation extends StatelessWidget {
  final List<AppDestination> destinations;
  final String location;

  const MobileRoleNavigation({
    super.key,
    required this.destinations,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final primaryCount = destinations.length > 4 ? 3 : destinations.length;
    final primary = destinations.take(primaryCount).toList();
    final secondary = destinations.skip(primaryCount).toList();
    final selectedPrimary =
        primary.indexWhere((item) => item.matches(location));
    final selectedIndex = selectedPrimary >= 0
        ? selectedPrimary
        : secondary.isNotEmpty
            ? primary.length
            : 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, primary.length),
        onDestinationSelected: (index) {
          if (index < primary.length) {
            context.go(primary[index].path);
            return;
          }
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            useSafeArea: true,
            builder: (context) => MoreNavigationSheet(
              destinations: secondary,
              location: location,
            ),
          );
        },
        destinations: [
          for (final destination in primary)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
          if (secondary.isNotEmpty)
            const NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_rounded),
              label: 'More',
            ),
        ],
      ),
    );
  }
}

class MoreNavigationSheet extends StatelessWidget {
  final List<AppDestination> destinations;
  final String location;

  const MoreNavigationSheet({
    super.key,
    required this.destinations,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text('More', style: context.textStyles.titleLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final destination in destinations)
            ListTile(
              minTileHeight: 52,
              leading: Icon(
                destination.matches(location)
                    ? destination.selectedIcon
                    : destination.icon,
              ),
              selected: destination.matches(location),
              selectedColor: AppColors.brandStrong,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              title: Text(destination.label),
              onTap: () {
                Navigator.pop(context);
                context.go(destination.path);
              },
            ),
          const Divider(height: AppSpacing.lg),
          ListTile(
            minTileHeight: 52,
            leading: const Icon(Icons.logout_rounded, color: AppColors.red),
            title: const Text('Sign out'),
            textColor: AppColors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}
