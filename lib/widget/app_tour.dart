import 'package:finance/Constans/constans.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TourStep {
  final GlobalKey key;
  final String title;
  final String body;
  final ContentAlign align;
  final ShapeLightFocus shape;
  const TourStep(
    this.key,
    this.title,
    this.body, {
    this.align = ContentAlign.bottom,
    this.shape = ShapeLightFocus.RRect,
  });
}

class AppTour {
  static bool _running = false;

  /// اگه این صفحه قبلاً دیده شده باشه یا تور دیگه‌ای در حال اجرا باشه، کاری نمی‌کنه.
  static void showOnce(
    BuildContext context, {
    required String page,
    required List<TourStep> steps,
    required bool Function() isMounted,
    required bool seen,
    required Future<void> Function() markSeen,
  }) {
    if (seen || _running) return;

    // فقط ویجت‌هایی که واقعاً روی صفحه ساخته شدن
    final valid = steps.where((s) => s.key.currentContext != null).toList();
    if (valid.isEmpty) return;

    _running = true;
    final targets = <TargetFocus>[];
    for (var i = 0; i < valid.length; i++) {
      final s = valid[i];
      final isLast = i == valid.length - 1;
      targets.add(
        TargetFocus(
          identify: '${page}_$i',
          keyTarget: s.key,
          shape: s.shape,
          radius: 16,
          enableOverlayTab: false,
          contents: [
            TargetContent(
              align: s.align,
              builder: (ctx, controller) => Directionality(
                textDirection: TextDirection.rtl,
                child: _Bubble(
                  title: s.title,
                  body: s.body,
                  step: '${i + 1} از ${valid.length}'.replaceAllMapped(
                    RegExp(r'\d'),
                    (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)],
                  ),
                  nextLabel: isLast ? 'تمام' : 'بعدی',
                  onNext: controller.next,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Future<void> done() async {
      _running = false;
      await markSeen();
    }

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.88,
      textSkip: 'رد کردن',
      textStyleSkip: const TextStyle(
        fontFamily: 'Lalezar',
        fontSize: 16,
        color: Colors.white,
      ),
      paddingFocus: 6,
      onFinish: done,
      onSkip: () {
        done();
        return true;
      },
    ).show(context: context);
  }
}

class _Bubble extends StatelessWidget {
  final String title, body, step, nextLabel;
  final VoidCallback onNext;
  const _Bubble({
    required this.title,
    required this.body,
    required this.step,
    required this.nextLabel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constans.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4C7DFF).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 20,
              color: Color(0xFF7FB2FF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              height: 1.7,
              color: Constans.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                step,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: Constans.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4C7DFF), Color(0xFF7C5CFF)],
                    ),
                  ),
                  child: Text(
                    nextLabel,
                    style: const TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
