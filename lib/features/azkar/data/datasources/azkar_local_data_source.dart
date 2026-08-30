import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/azkar_category_model.dart';
import '../models/dhikr_model.dart';

abstract interface class AzkarLocalDataSource {
  Future<List<AzkarCategoryModel>> loadCategories();
}

class AssetAzkarLocalDataSource implements AzkarLocalDataSource {
  AssetAzkarLocalDataSource([AssetBundle? bundle])
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const _morningEveningAsset = 'assets/data/azkar/morning_evening.json';
  static const _afterSalahAsset = 'assets/data/azkar/after_salah.json';
  static const _dailyDuaAsset = 'assets/data/azkar/daily_dua.json';

  @override
  Future<List<AzkarCategoryModel>> loadCategories() async {
    final contents = await Future.wait([
      _bundle.loadString(_morningEveningAsset),
      _bundle.loadString(_afterSalahAsset),
      _bundle.loadString(_dailyDuaAsset),
    ]);
    final morningEvening = _decodeList(contents[0], _morningEveningAsset);
    final afterSalah = _decodeList(contents[1], _afterSalahAsset);
    final dailyDuas = _decodeList(contents[2], _dailyDuaAsset);

    final morning = <DhikrModel>[];
    final evening = <DhikrModel>[];
    for (final value in morningEvening) {
      final type = _requiredInt(value, 'type');
      final model = DhikrModel(
        id: 'me-${_requiredInt(value, 'order')}',
        arabicText: _requiredString(value, 'content'),
        translation: _optionalString(value, 'translation'),
        repeatCount: _positiveCount(value['count']),
        reference: _requiredString(value, 'source'),
      );
      if (type == 0 || type == 1) morning.add(model);
      if (type == 0 || type == 2) evening.add(model);
    }

    final afterPrayer = <DhikrModel>[
      for (var index = 0; index < afterSalah.length; index++)
        _fromDua(afterSalah[index], 'ap-${index + 1}'),
    ];
    final grouped = <String, List<DhikrModel>>{
      'sleep': <DhikrModel>[],
      'waking': <DhikrModel>[],
      'mosque': <DhikrModel>[],
      'home': <DhikrModel>[],
      'food': <DhikrModel>[],
      'travel': <DhikrModel>[],
      'general': <DhikrModel>[],
    };
    for (var index = 0; index < dailyDuas.length; index++) {
      final value = dailyDuas[index];
      final title = _requiredString(value, 'title').toLowerCase();
      grouped[_categoryForTitle(title)]!.add(
        _fromDua(value, 'dd-${index + 1}'),
      );
    }

    final categories = <AzkarCategoryModel>[
      AzkarCategoryModel(
        id: 'morning',
        titleKey: 'morning_azkar',
        isDaily: true,
        items: morning,
      ),
      AzkarCategoryModel(
        id: 'evening',
        titleKey: 'evening_azkar',
        isDaily: true,
        items: evening,
      ),
      AzkarCategoryModel(
        id: 'after_prayer',
        titleKey: 'after_prayer_azkar',
        isDaily: true,
        items: afterPrayer,
      ),
      AzkarCategoryModel(
        id: 'sleep',
        titleKey: 'sleep_azkar',
        isDaily: false,
        items: grouped['sleep']!,
      ),
      AzkarCategoryModel(
        id: 'waking',
        titleKey: 'wake_up_azkar',
        isDaily: false,
        items: grouped['waking']!,
      ),
      AzkarCategoryModel(
        id: 'mosque',
        titleKey: 'mosque_azkar',
        isDaily: false,
        items: grouped['mosque']!,
      ),
      AzkarCategoryModel(
        id: 'home',
        titleKey: 'home_azkar',
        isDaily: false,
        items: grouped['home']!,
      ),
      AzkarCategoryModel(
        id: 'food',
        titleKey: 'food_azkar',
        isDaily: false,
        items: grouped['food']!,
      ),
      AzkarCategoryModel(
        id: 'travel',
        titleKey: 'travel_azkar',
        isDaily: false,
        items: grouped['travel']!,
      ),
      AzkarCategoryModel(
        id: 'general',
        titleKey: 'general_azkar',
        isDaily: false,
        items: grouped['general']!,
      ),
    ];
    if (categories.any((category) => category.items.isEmpty)) {
      throw const FormatException('An Azkar category contains no items.');
    }
    return categories;
  }

  static List<Map<String, dynamic>> _decodeList(String value, String source) {
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw FormatException('Expected a list in $source.');
    }
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw FormatException('Invalid Azkar record in $source.');
          }
          return item;
        })
        .toList(growable: false);
  }

  static DhikrModel _fromDua(Map<String, dynamic> value, String id) =>
      DhikrModel(
        id: id,
        arabicText: _requiredString(value, 'arabic'),
        translation: _optionalString(value, 'translation'),
        repeatCount: _countFromNotes(value['notes']),
        reference: _optionalString(value, 'source'),
      );

  static String _categoryForTitle(String title) {
    if (title.contains('sleeping')) return 'sleep';
    if (title.contains('waking')) return 'waking';
    if (title.contains('mosque')) return 'mosque';
    if (title.contains('house')) return 'home';
    if (title.contains('eating') ||
        title.contains('meal') ||
        title.contains('breaking the fast')) {
      return 'food';
    }
    if (title.contains('travel') || title.contains('vehicle')) return 'travel';
    return 'general';
  }

  static int _countFromNotes(Object? notes) {
    final match = RegExp(r'(\d+)').firstMatch(notes?.toString() ?? '');
    return _positiveCount(match == null ? 1 : int.parse(match.group(1)!));
  }

  static int _positiveCount(Object? value) {
    final count = value is int ? value : int.tryParse('$value');
    return count != null && count > 0 ? count : 1;
  }

  static String _requiredString(Map<String, dynamic> value, String key) {
    final result = value[key];
    if (result is! String || result.trim().isEmpty) {
      throw FormatException('Missing Azkar field: $key.');
    }
    return result.trim();
  }

  static int _requiredInt(Map<String, dynamic> value, String key) {
    final result = value[key];
    final parsed = result is int ? result : int.tryParse('$result');
    if (parsed == null) throw FormatException('Missing Azkar field: $key.');
    return parsed;
  }

  static String _optionalString(Map<String, dynamic> value, String key) =>
      value[key] is String ? (value[key] as String).trim() : '';
}
