import '../../domain/entities/azkar_category.dart';
import 'dhikr_model.dart';

class AzkarCategoryModel {
  const AzkarCategoryModel({
    required this.id,
    required this.titleKey,
    required this.isDaily,
    required this.items,
  });

  final String id;
  final String titleKey;
  final bool isDaily;
  final List<DhikrModel> items;

  AzkarCategory toEntity() => AzkarCategory(
    id: id,
    titleKey: titleKey,
    isDaily: isDaily,
    items: items.map((item) => item.toEntity(id)).toList(growable: false),
  );
}
