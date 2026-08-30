import '../../domain/entities/surah.dart';
import 'ayah_model.dart';

class SurahModel {
  const SurahModel({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    this.ayahs = const <AyahModel>[],
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'];
    final ayahs = rawAyahs == null
        ? const <AyahModel>[]
        : _parseAyahs(rawAyahs);
    return SurahModel(
      number: _requiredInt(json, 'number'),
      arabicName: _requiredString(json, 'name'),
      englishName: _requiredString(json, 'englishName'),
      englishNameTranslation: _requiredString(json, 'englishNameTranslation'),
      revelationType: _requiredString(json, 'revelationType'),
      numberOfAyahs: _requiredInt(json, 'numberOfAyahs'),
      ayahs: ayahs,
    );
  }

  final int number;
  final String arabicName;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<AyahModel> ayahs;

  Surah toEntity() => Surah(
    number: number,
    arabicName: arabicName,
    englishName: englishName,
    englishNameTranslation: englishNameTranslation,
    revelationType: revelationType,
    numberOfAyahs: numberOfAyahs,
    ayahs: ayahs.map((ayah) => ayah.toEntity()).toList(growable: false),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'name': arabicName,
    'englishName': englishName,
    'englishNameTranslation': englishNameTranslation,
    'revelationType': revelationType,
    'numberOfAyahs': numberOfAyahs,
    if (ayahs.isNotEmpty)
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(growable: false),
  };
}

List<AyahModel> _parseAyahs(Object value) {
  if (value is! List) throw const FormatException('Invalid Ayah list');
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid Ayah entry');
        }
        return AyahModel.fromJson(item);
      })
      .toList(growable: false);
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Invalid integer field: $key');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Invalid string field: $key');
}
