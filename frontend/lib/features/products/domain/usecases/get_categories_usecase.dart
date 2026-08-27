import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Use case for fetching active marketplace categories.
class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Result<List<Category>>> call() {
    return _repository.getCategories();
  }
}
