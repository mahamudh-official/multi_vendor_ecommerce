import '../../../../core/error/result.dart';
import '../entities/order.dart';
import '../entities/order_status.dart';
import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  const GetOrdersUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<List<Order>>> call({
    OrderStatus? status,
    int page = 1,
    int pageSize = 10,
  }) => _repository.getOrders(status: status, page: page, pageSize: pageSize);
}
