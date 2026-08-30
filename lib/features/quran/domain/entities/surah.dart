import 'ayah.dart';

class Surah {
  const Surah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    this.ayahs = const <Ayah>[],
  });

  final int number;
  final String arabicName;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<Ayah> ayahs;

  bool get isMeccan => revelationType.toLowerCase() == 'meccan';
}
