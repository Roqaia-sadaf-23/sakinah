import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  late final SharedPreferences _preferences;

  Future<StorageService> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    return this;
  }

  String? readString(String key) => _preferences.getString(key);

  bool? readBool(String key) => _preferences.getBool(key);

  Future<bool> writeString(String key, String value) =>
      _preferences.setString(key, value);

  Future<bool> writeBool(String key, bool value) =>
      _preferences.setBool(key, value);

  Map<String, dynamic>? readJson(String key) {
    final value = readString(key);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<bool> writeJson(String key, Map<String, dynamic> value) =>
      writeString(key, jsonEncode(value));
}
