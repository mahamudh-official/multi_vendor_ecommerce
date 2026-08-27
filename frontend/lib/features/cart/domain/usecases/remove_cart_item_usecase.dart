import '../../../../core/error/result.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class RemoveCartItemUseCase {
  const RemoveCartItemUseCase(this._repository);

  final CartRepository _repository;

  Future<Result<Cart>> call({required String itemId}) =>
      _repository.removeCartItem(itemId: itemId);
}
