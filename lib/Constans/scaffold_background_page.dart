import 'package:flutter/material.dart';

//todos fix this background for all page of this app so this is important ask anyone that you know it

/// هاله‌ی آبی که پشت اپ‌بار/بالای صفحه قرار می‌گیره.
/// این رو دور محتوای هر صفحه با یه Stack می‌پیچونی.
class AppGlowBackground extends StatelessWidget {
  const AppGlowBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF0A0E27),
    this.glowColor = const Color(0xFF4682FF),
    this.glowSize = 380,
    this.top = -180,
    this.left = -140,
  });

  final Widget child;
  final Color backgroundColor;
  final Color glowColor;
  final double glowSize;
  final double top;
  final double left;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          Positioned(
            top: top,
            left: left,
            child: Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: 0.7),
                    glowColor.withValues(alpha: 0.32),
                    glowColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.45, 0.72],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
