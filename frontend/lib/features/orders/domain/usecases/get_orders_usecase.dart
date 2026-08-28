import '../../../../core/error/result.dart';
import '../entities/order.dart';
import '../entities/order_status.dart';
import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  const GetOrdersUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<List<Order>>> call({
    OrderStatus? status,
    String? search,
    String? sort,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 10,
  }) => _repository.getOrders(
    status: status,
    search: search,
    sort: sort,
    fromDate: fromDate,
    toDate: toDate,
    page: page,
    pageSize: pageSize,
  );
}
