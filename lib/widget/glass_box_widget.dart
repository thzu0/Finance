import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';

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

// ==========================================
// رنگ‌ها و استایل مشترک صفحه‌های پروفایل
// ==========================================
const Color kAccent = Color(0xFF4C7DFF);
const Color kAccent2 = Color(0xFF7C5CFF);
const Color kDanger = Color(0xFFFF5470);
const Color kSuccess = Color(0xFF2ED8A3);
const Color kSectionBlue = Color(0xFF7FB2FF);
const Color kDialogBg = Color(0xFF0B1B4A);

TextStyle glassText(double size, {Color? color}) => TextStyle(
  fontFamily: 'Lalezar',
  fontSize: size,
  color: color ?? Constans.textPrimary,
);

// ==========================================
// اسکلت مشترک همه‌ی صفحه‌های داخلی
// دکمه‌ی برگشت سمت راست، کنار تیتر
// ==========================================
class GlassPage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const GlassPage({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constans.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Constans.textPrimary,
                    fontFamily: 'Lalezar',
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                GlassBox(
                  height: 44,
                  width: 44,
                  radius: 14,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Constans.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: AppGlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            // ۸۰ = ارتفاع اپ‌بار، تا محتوا زیر تیتر نره
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 40),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// عنوان هر بخش
// ==========================================
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Text(text, style: glassText(17, color: kSectionBlue)),
    );
  }
}

// ==========================================
// کارت شیشه‌ای که چند ردیف رو با خط جداکننده نگه می‌داره
// ==========================================
class GlassGroup extends StatelessWidget {
  final List<Widget> children;
  const GlassGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: kAccent.withValues(alpha: 0.18),
              ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// یه ردیف: آیکون + عنوان + زیرعنوان + (فلش یا ویجت دلخواه)
// ==========================================
class GlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color; // برای ردیف‌های خطرناک (قرمز)

  const GlassTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? kSectionBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: glassText(17, color: color)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: glassText(13, color: Constans.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Constans.textSecondary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ردیف با سوییچ
// ==========================================
class GlassSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? kAccent
              : Colors.white.withValues(alpha: 0.18),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

// ==========================================
// انتخاب‌گر چندحالته (مثل تب‌بارِ صفحه‌ی تراکنش‌ها)
// ==========================================
class GlassSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const GlassSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      height: 46,
      radius: 14,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSel = selected == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: isSel
                      ? const LinearGradient(colors: [kAccent, kAccent2])
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: glassText(
                    16,
                    color: isSel ? Colors.white : Constans.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ==========================================
// اسنک‌بار
// ==========================================
void showGlassSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF16265E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: kAccent.withValues(alpha: 0.5)),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: glassText(15),
        ),
      ),
    );
}

// ==========================================
// دیالوگ تایید
// ==========================================
Future<bool> showGlassConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'تایید',
  bool danger = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: kDialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: kAccent.withValues(alpha: 0.5)),
        ),
        title: Text(title, style: glassText(20)),
        content: Text(
          message,
          style: glassText(15, color: Constans.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'انصراف',
              style: glassText(16, color: Constans.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmText,
              style: glassText(16, color: danger ? kDanger : kAccent),
            ),
          ),
        ],
      ),
    ),
  );
  return res ?? false;
}

// ==========================================
// دیالوگ فرم (یک یا چند فیلد)
// ==========================================
class GlassFormField {
  final String label;
  final String initial;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboard;

  const GlassFormField({
    required this.label,
    this.initial = '',
    this.obscure = false,
    this.maxLines = 1,
    this.keyboard,
  });
}

InputDecoration glassInputDecoration(String label) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: glassText(15, color: Constans.textSecondary),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: border(kAccent.withValues(alpha: 0.4)),
    enabledBorder: border(kAccent.withValues(alpha: 0.4)),
    focusedBorder: border(kAccent),
  );
}

/// مقدارهای فیلدها رو برمی‌گردونه، یا null اگه انصراف داده بشه.
/// validate می‌تونه متن خطا برگردونه تا تو دیالوگ نشون داده بشه.
Future<List<String>?> showGlassForm(
  BuildContext context, {
  required String title,
  required List<GlassFormField> fields,
  String confirmText = 'ذخیره',
  String? Function(List<String> values)? validate,
}) {
  final controllers = fields
      .map((f) => TextEditingController(text: f.initial))
      .toList();
  String? error;

  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: kDialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: kAccent.withValues(alpha: 0.5)),
          ),
          title: Text(title, style: glassText(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < fields.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[i],
                      obscureText: fields[i].obscure,
                      maxLines: fields[i].obscure ? 1 : fields[i].maxLines,
                      keyboardType: fields[i].keyboard,
                      style: glassText(16),
                      decoration: glassInputDecoration(fields[i].label),
                    ),
                  ),
                if (error != null)
                  Text(error!, style: glassText(14, color: kDanger)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'انصراف',
                style: glassText(16, color: Constans.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final values = controllers.map((c) => c.text.trim()).toList();
                final err = validate?.call(values);
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(ctx, values);
              },
              child: Text(confirmText, style: glassText(16, color: kAccent)),
            ),
          ],
        ),
      ),
    ),
  );
}
