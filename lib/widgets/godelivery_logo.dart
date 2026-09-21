import 'package:flutter/material.dart';

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
          color: const Color(0xFF17243B),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160E1A2B),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: image,
    );
  }
}
