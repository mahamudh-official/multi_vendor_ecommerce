import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

/// Implementation of CategoryRepository handling exceptions and entity mapping.
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._remoteDataSource);

  final CategoryRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final models = await _remoteDataSource.getCategories();
      return Success(models.map((m) => m.toEntity()).toList());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Category>> getCategoryDetails(String id) async {
    try {
      final model = await _remoteDataSource.getCategoryDetails(id);
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
