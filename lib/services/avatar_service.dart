import 'dart:io';
import 'package:finance/database/app_setting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AvatarService {
  static final _picker = ImagePicker();
  static const _key = 'avatar_path';

  /// مسیر عکس ذخیره‌شده؛ null یعنی عکسی انتخاب نشده یا فایل پاک شده
  static String? get path {
    final v = AppSettings.instance.get<String>(_key, '');
    if (v.isEmpty || !File(v).existsSync()) return null;
    return v;
  }

  /// عکس رو انتخاب می‌کنه، توی پوشه‌ی اپ کپی می‌کنه و مسیرش رو ذخیره می‌کنه
  static Future<bool> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return false;

    final dir = await getApplicationDocumentsDirectory();
    // اسم یکتا تا کش تصویر موقع عوض کردن عکس مشکل نسازه
    final dest = p.join(
      dir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(picked.path).copy(dest);

    // عکس قبلی رو پاک کن
    final old = path;
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }

    await AppSettings.instance.set(_key, dest);
    return true;
  }

  static Future<void> remove() async {
    final old = path;
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    await AppSettings.instance.set(_key, '');
  }
}
