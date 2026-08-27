import '../../../../core/error/result.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class AddToCartUseCase {
  const AddToCartUseCase(this._repository);

  final CartRepository _repository;

  Future<Result<Cart>> call({
    required String productId,
    required int quantity,
  }) => _repository.addToCart(productId: productId, quantity: quantity);
}
