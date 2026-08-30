import '../entities/azkar_category.dart';
import '../repositories/azkar_repository.dart';

class GetAzkarCategories {
  const GetAzkarCategories(this._repository);

  final AzkarRepository _repository;

  Future<List<AzkarCategory>> call() => _repository.getCategories();
}
