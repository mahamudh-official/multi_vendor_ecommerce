import '../../../../core/error/result.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class UpdateCartItemUseCase {
  const UpdateCartItemUseCase(this._repository);

  final CartRepository _repository;

  Future<Result<Cart>> call({required String itemId, required int quantity}) =>
      _repository.updateCartItemQuantity(itemId: itemId, quantity: quantity);
}
