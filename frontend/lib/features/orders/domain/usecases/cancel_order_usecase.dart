import '../../../../core/error/result.dart';
import '../repositories/order_repository.dart';

class CancelOrderUseCase {
  const CancelOrderUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<void>> call(String orderId) => _repository.cancelOrder(orderId);
}
