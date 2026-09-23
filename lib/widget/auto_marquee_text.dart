import 'package:flutter/material.dart';

/// متن تک‌خطی که اگه جا شد همون Text معمولیه،
/// و اگه جا نشد مثل تابلوی مغازه می‌چرخه.
/// باید تو یه ویجت با عرض محدود (مثلاً Expanded) استفاده بشه.
class AutoMarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  /// فاصله‌ی بین آخر متن و شروع دوباره‌ش
  final double gap;

  /// سرعت حرکت (پیکسل بر ثانیه)
  final double velocity;

  const AutoMarqueeText(
    this.text, {
    super.key,
    this.style,
    this.gap = 28,
    this.velocity = 40,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          textDirection: TextDirection.rtl,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        final textWidth = painter.width;
        final textHeight = painter.height;
        painter.dispose();

        if (textWidth <= constraints.maxWidth) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          );
        }

        return SizedBox(
          height: textHeight,
          child: _MarqueeScroller(
            text: text,
            style: effectiveStyle,
            textWidth: textWidth,
            gap: gap,
            velocity: velocity,
          ),
        );
      },
    );
  }
}

class _MarqueeScroller extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double textWidth;
  final double gap;
  final double velocity;

  const _MarqueeScroller({
    required this.text,
    required this.style,
    required this.textWidth,
    required this.gap,
    required this.velocity,
  });

  @override
  State<_MarqueeScroller> createState() => _MarqueeScrollerState();
}

class _MarqueeScrollerState extends State<_MarqueeScroller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double get _distance => widget.textWidth + widget.gap;

  Duration get _duration =>
      Duration(milliseconds: (_distance / widget.velocity * 1000).round());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant _MarqueeScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textWidth != widget.textWidth ||
        oldWidget.gap != widget.gap ||
        oldWidget.velocity != widget.velocity) {
      _controller.duration = _duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(_controller.value * _distance, 0),
          child: child,
        ),
        child: OverflowBox(
          alignment: Alignment.centerRight,
          minWidth: 0,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                widget.text,
                style: widget.style,
                maxLines: 1,
                softWrap: false,
              ),
              SizedBox(width: widget.gap),
              Text(
                widget.text,
                style: widget.style,
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
