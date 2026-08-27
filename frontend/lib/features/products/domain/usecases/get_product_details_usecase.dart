import '../../../../core/error/result.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case for fetching complete product details by ID.
class GetProductDetailsUseCase {
  const GetProductDetailsUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<Product>> call(String id) {
    return _repository.getProductDetails(id);
  }
}
