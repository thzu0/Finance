import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  final ValueNotifier<int> changes = ValueNotifier(0);
  Map<String, dynamic> _data = {};
  File? _file;

  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/settings.json');
    if (await _file!.exists()) {
      try {
        _data = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        _data = {};
      }
    }
  }

  T get<T>(String key, T fallback) {
    final v = _data[key];
    return v is T ? v : fallback;
  }

  Future<void> set(String key, Object value) async {
    _data[key] = value;
    changes.value++;
    await _file?.writeAsString(jsonEncode(_data));
  }

  Future<void> clearAll() async {
    _data = {};
    changes.value++;
    await _file?.writeAsString('{}');
  }
}
