import '../../../../core/error/result.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class GetOrderDetailsUseCase {
  const GetOrderDetailsUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<Order>> call(String orderId) =>
      _repository.getOrderDetails(orderId);
}
