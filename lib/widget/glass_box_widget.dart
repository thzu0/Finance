import 'dart:ui';

import 'package:flutter/material.dart';

/// کانتینر شیشه‌ای: بلور پس‌زمینه + گرادیانت آبی نیمه‌شفاف + بردر آبی
class GlassBox extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;
  final Color color;

  const GlassBox({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.radius = 18,
    this.blur = 14,
    this.color = const Color(0xFF4C7DFF), // آبی اصلی، هر رنگی خواستی بذار
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          width: width,
          padding: padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.24),
                color.withValues(alpha: 0.07),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
