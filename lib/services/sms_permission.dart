import 'package:finance/database/card_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// نتیجه‌ی درخواست دسترسی پیامک
enum SmsPermissionResult {
  granted, // کاربر قبول کرد
  denied, // کاربر رد کرد (می‌تونه دوباره بپرسه)
  permanentlyDenied, // کاربر کلاً رد کرده، باید به تنظیمات بره
}

class SmsPermissionService {
  SmsPermissionService._();

  /// درخواست دسترسی + ذخیره‌ی وضعیت
  static Future<SmsPermissionResult> request() async {
    final status = await Permission.sms.request();

    if (status.isGranted) {
      await CardService.instance.setSmsParsing(true);
      return SmsPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      await CardService.instance.setSmsParsing(false);
      return SmsPermissionResult.permanentlyDenied;
    }

    await CardService.instance.setSmsParsing(false);
    return SmsPermissionResult.denied;
  }

  /// خاموش کردن دسترسی (کاربر خودش سوییچ رو خاموش کرد)
  static Future<void> disable() async {
    await CardService.instance.setSmsParsing(false);
  }

  /// چک کردن این‌که دسترسی هنوز پابرجاست یا نه
  /// برمی‌گردونه: آیا سوییچ باید روشن باشه؟
  static Future<bool> isStillGranted() async {
    if (!CardService.instance.isSmsParsingEnabled()) return false;
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      // دسترسی پس گرفته شده، سوییچ رو خاموش کن
      await CardService.instance.setSmsParsing(false);
      return false;
    }
    return true;
  }

  /// باز کردن تنظیمات اپ برای این‌که کاربر دستی دسترسی بده
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// نمایش پیام مناسب بر اساس نتیجه
  static Future<void> handleResult(
    BuildContext context,
    SmsPermissionResult result, {
    required VoidCallback onGranted,
  }) async {
    switch (result) {
      case SmsPermissionResult.granted:
        onGranted();
        break;
      case SmsPermissionResult.denied:
        if (!context.mounted) return;
        _showSnack(context, 'برای خواندن پیامک‌ها، دسترسی لازمه');
        break;
      case SmsPermissionResult.permanentlyDenied:
        if (!context.mounted) return;
        _showSettingsDialog(context);
        break;
    }
  }

  static void _showSnack(BuildContext context, String message) {
    // از تابع خودت استفاده کن
    // این‌جا ساده‌ش می‌کنم
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دسترسی به پیامک'),
        content: const Text(
          'برای خواندن خودکار پیامک‌های بانکی، باید توی تنظیمات گوشی دسترسی بدی. الان بریم؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بعداً'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('برو به تنظیمات'),
          ),
        ],
      ),
    );
  }
}
