import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

/// Reusable brand mark which keeps the supplied GoDelivery artwork crisp on
/// light and dark surfaces.
class GoDeliveryLogo extends StatelessWidget {
  final double height;
  final bool withSurface;

  const GoDeliveryLogo({
    super.key,
    this.height = 44,
    this.withSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/godelivery_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        'GoDelivery',
        style: TextStyle(
          color: context.colors.onSurface,
          fontSize: height * .46,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
        ),
      ),
    );

    if (!withSurface) return image;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: AppShadows.raised,
      ),
      child: image,
    );
  }
}
