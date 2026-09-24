import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_tokens.dart';

class AppContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContent,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.all(context.pagePadding),
          child: child,
        ),
      ),
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool emphasized;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);
    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: borderRadius,
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: emphasized ? AppShadows.raised : AppShadows.subtle,
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: content,
              ),
            ),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? eyebrow;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.compact;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              eyebrow!,
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(title, style: context.textStyles.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        );

        if (actions.isEmpty) return copy;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: AppSpacing.md),
              Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: copy),
            const SizedBox(width: AppSpacing.lg),
            Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: actions),
          ],
        );
      },
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textStyles.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: context.textStyles.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final Color color;
  final Widget? footer;

  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hint,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              if (hint != null)
                Flexible(
                  child: Text(
                    hint!,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}

class AppResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double mainAxisExtent;
  final int maxColumns;
  final double spacing;

  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 220,
    this.mainAxisExtent = 160,
    this.maxColumns = 4,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth + spacing;
        final calculated = (available / (minItemWidth + spacing)).floor();
        final columns = calculated.clamp(1, maxColumns);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class AppLoadingState extends StatelessWidget {
  final String message;

  const AppLoadingState({super.key, this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(message, style: context.textStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title,
                  style: context.textStyles.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: Icons.cloud_off_outlined,
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              key: const Key('state_retry_button'),
              onPressed: () => onRetry!(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
    );
  }
}

class AppInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final TextStyle? valueStyle;

  const AppInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueStyle ?? context.textStyles.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStatusStyle {
  final String label;
  final Color color;
  final IconData icon;

  const OrderStatusStyle(this.label, this.color, this.icon);

  static OrderStatusStyle from(String rawStatus) {
    final status = rawStatus.trim().toUpperCase().replaceAll(' ', '_');
    return switch (status) {
      'WAREHOUSE' => const OrderStatusStyle(
          'Warehouse', AppColors.blue, Icons.warehouse_outlined),
      'NEW' =>
        const OrderStatusStyle('New', AppColors.amber, Icons.fiber_new_rounded),
      'PICKED_UP' || 'PICKEDUP' => const OrderStatusStyle(
          'Picked up', AppColors.violet, Icons.local_shipping_outlined),
      'DELIVERED' => const OrderStatusStyle(
          'Delivered', AppColors.teal, Icons.check_circle_outline_rounded),
      'CANCELLED' || 'CANCELED' => const OrderStatusStyle(
          'Cancelled', AppColors.red, Icons.cancel_outlined),
      'PAID' =>
        const OrderStatusStyle('Paid', AppColors.cyan, Icons.payments_outlined),
      'COLLECTED' => const OrderStatusStyle(
          'Collected', AppColors.navy, Icons.inventory_outlined),
      _ => OrderStatusStyle(
          rawStatus, AppColors.inkMuted, Icons.help_outline_rounded),
    };
  }
}

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = OrderStatusStyle.from(status);
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final color = darkMode &&
            (style.color == AppColors.navy || style.color == AppColors.inkMuted)
        ? context.colors.onSurfaceVariant
        : style.color;
    return Semantics(
      label: 'Order status: ${style.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(style.icon, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              style.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatLbp(double amount) =>
    'LBP ${NumberFormat('#,##0.##').format(amount)}';

String shortIdentifier(String value, {int length = 10}) =>
    value.length <= length ? value : value.substring(0, length);
