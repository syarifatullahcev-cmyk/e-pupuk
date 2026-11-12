import 'package:flutter/material.dart';

/// Logo Resmi E-Pupuk (Kecambah Hijau / Sprout Emerald).
/// Sesuai dengan desain sistem E-Pupuk Kabupaten Mojokerto.
class AppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool hasShadow;

  const AppLogo({
    super.key,
    this.size = 38.0,
    this.borderRadius,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? (size * 0.26);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF009B69).withValues(alpha: 0.30),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

