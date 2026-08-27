import '../../../../core/error/result.dart';
import '../repositories/product_repository.dart';

/// Use case for soft-deleting a product listing.
class DeleteProductUseCase {
  const DeleteProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<void>> call(String id) {
    return _repository.deleteProduct(id);
  }
}
