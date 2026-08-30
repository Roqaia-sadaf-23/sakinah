import '../../domain/entities/ayah.dart';

class AyahModel {
  const AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    final text = _requiredString(json, 'text').replaceFirst('\uFEFF', '');
    return AyahModel(
      number: _requiredInt(json, 'number'),
      numberInSurah: _requiredInt(json, 'numberInSurah'),
      text: text,
      juz: _requiredInt(json, 'juz'),
      page: _requiredInt(json, 'page'),
    );
  }

  final int number;
  final int numberInSurah;
  final String text;
  final int juz;
  final int page;

  Ayah toEntity() => Ayah(
    number: number,
    numberInSurah: numberInSurah,
    text: text.replaceFirst('\uFEFF', ''),
    juz: juz,
    page: page,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'numberInSurah': numberInSurah,
    'text': text,
    'juz': juz,
    'page': page,
  };
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
