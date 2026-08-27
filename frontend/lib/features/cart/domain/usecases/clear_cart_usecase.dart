import '../../../../core/error/result.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class ClearCartUseCase {
  const ClearCartUseCase(this._repository);

  final CartRepository _repository;

  Future<Result<Cart>> call() => _repository.clearCart();
}
