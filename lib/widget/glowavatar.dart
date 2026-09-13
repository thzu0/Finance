import 'package:flutter/material.dart';

/// اواتار پروفایل با حاشیه‌ی روشن و افکت درخشش (elevation) مطابق طرح.
class GlowAvatar extends StatelessWidget {
  const GlowAvatar({
    super.key,
    this.imageProvider,
    this.size = 48,
    this.borderColor = const Color(0xFFC8DCFB),
    this.borderWidth = 2,
    this.glowColor = const Color(0xFF78AAFF),
  });

  /// عکس پروفایل. اگه null باشه یه آیکون پیش‌فرض نشون داده میشه.
  final ImageProvider? imageProvider;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFF4A6FA8),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(
                Icons.person,
                color: Colors.white.withValues(alpha: 0.8),
                size: size * 0.5,
              )
            : null,
      ),
    );
  }
}
