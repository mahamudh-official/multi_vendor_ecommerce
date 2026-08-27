import '../../../../core/error/result.dart';
import '../entities/category.dart';

/// Abstract contract for category operations.
abstract interface class CategoryRepository {
  Future<Result<List<Category>>> getCategories();
  Future<Result<Category>> getCategoryDetails(String id);
}
