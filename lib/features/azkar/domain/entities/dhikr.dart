class Dhikr {
  const Dhikr({
    required this.id,
    required this.categoryId,
    required this.arabicText,
    required this.translation,
    required this.repeatCount,
    required this.reference,
  });

  final String id;
  final String categoryId;
  final String arabicText;
  final String translation;
  final int repeatCount;
  final String reference;
}
