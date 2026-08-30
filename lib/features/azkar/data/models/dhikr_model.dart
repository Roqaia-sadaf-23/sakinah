import '../../domain/entities/dhikr.dart';

class DhikrModel {
  const DhikrModel({
    required this.id,
    required this.arabicText,
    required this.translation,
    required this.repeatCount,
    required this.reference,
  });

  final String id;
  final String arabicText;
  final String translation;
  final int repeatCount;
  final String reference;

  Dhikr toEntity(String categoryId) => Dhikr(
    id: id,
    categoryId: categoryId,
    arabicText: arabicText,
    translation: translation,
    repeatCount: repeatCount,
    reference: reference,
  );
}
