import 'package:finance/database/app_setting.dart';
import 'package:flutter/material.dart';

import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static final _s = AppSettings.instance;

  /// آیا کاربر اثر انگشت رو توی تنظیمات اپ فعال کرده؟
  static bool get isEnabled => _s.get<bool>('biometric', false);

  /// آیا این دستگاه اصلاً از بیومتریک پشتیبانی می‌کنه؟
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  /// لیست بیومتریک‌های ثبت‌شده روی گوشی (خالی = هیچی ثبت نشده)
  static Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    } on LocalAuthException {
      return [];
    }
  }

  static Future<void> enable() => _s.set('biometric', true);
  static Future<void> disable() => _s.set('biometric', false);

  /// تأیید هویت با اثر انگشت/چهره.
  /// true برگردونه یعنی کاربر تأیید شد.
  static Future<bool> authenticate({
    String reason = 'برای ورود به برنامه هویتت رو تأیید کن',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  static Future<void> debugCapabilities() async {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    final types = await _auth.getAvailableBiometrics();
    debugPrint('isDeviceSupported: $supported');
    debugPrint('canCheckBiometrics: $canCheck');
    debugPrint('availableBiometrics: $types');
  }
}
