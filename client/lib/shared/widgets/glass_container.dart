import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.25,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Default dynamic backdrop tint
    final baseColor = color ?? (isDark ? const Color(0xFF161325) : const Color(0xFFEDE7D5));
    final containerColor = baseColor.withValues(alpha: opacity);

    // Default dynamic border
    final defaultBorder = border ?? Border.all(
      color: isDark 
          ? Colors.white.withValues(alpha: 0.08) 
          : Colors.black.withValues(alpha: 0.06),
      width: 1.0,
    );

    final defaultRadius = borderRadius ?? BorderRadius.circular(12.0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: defaultRadius,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x15000000) : const Color(0x06000000),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: defaultRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: defaultRadius,
              border: defaultBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
