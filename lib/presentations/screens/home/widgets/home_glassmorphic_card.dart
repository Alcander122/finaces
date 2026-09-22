import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/theme.dart';

class HomeGlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double borderOpacity;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double? height;

  const HomeGlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.borderOpacity = 0.1,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(20.0),
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final defaultBg = isDark
        ? const Color(0x0DFFFFFF)
        : Colors.white.withValues(alpha: 0.9);
    final cardBg = backgroundColor ?? defaultBg;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: borderOpacity)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isDark ? 30 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
