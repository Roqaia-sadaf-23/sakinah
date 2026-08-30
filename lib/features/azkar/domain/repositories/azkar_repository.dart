import '../entities/azkar_category.dart';
import '../entities/azkar_position.dart';

abstract interface class AzkarRepository {
  Future<List<AzkarCategory>> getCategories();

  Future<Map<String, int>> getCounts(AzkarCategory category);

  Future<void> saveCounts(AzkarCategory category, Map<String, int> counts);

  Set<String> getFavoriteIds();

  Future<void> saveFavoriteIds(Set<String> ids);

  AzkarPosition? getLastPosition();

  Future<void> saveLastPosition(AzkarPosition position);

  double getFontSize();

  Future<void> saveFontSize(double size);
}
