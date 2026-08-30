class Reciter {
  const Reciter({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.audioIdentifier,
  });

  final String id;
  final String arabicName;
  final String englishName;
  final String audioIdentifier;
}

abstract final class SupportedReciters {
  static const misharyAlafasy = Reciter(
    id: 'alafasy',
    arabicName: 'مشاري راشد العفاسي',
    englishName: 'Mishary Rashid Alafasy',
    audioIdentifier: 'ar.alafasy',
  );

  static const abdulBasit = Reciter(
    id: 'abdul_basit_murattal',
    arabicName: 'عبد الباسط عبد الصمد',
    englishName: 'Abdul Basit Abdus-Samad',
    audioIdentifier: 'ar.abdulbasitmurattal',
  );

  static const husary = Reciter(
    id: 'husary',
    arabicName: 'محمود خليل الحصري',
    englishName: 'Mahmoud Khalil Al-Husary',
    audioIdentifier: 'ar.husary',
  );

  static const minshawi = Reciter(
    id: 'minshawi',
    arabicName: 'محمد صديق المنشاوي',
    englishName: 'Muhammad Siddiq Al-Minshawi',
    audioIdentifier: 'ar.minshawi',
  );

  static const all = <Reciter>[misharyAlafasy, abdulBasit, husary, minshawi];

  static Reciter fromId(String? id) => all.firstWhere(
    (reciter) => reciter.id == id,
    orElse: () => misharyAlafasy,
  );
}
