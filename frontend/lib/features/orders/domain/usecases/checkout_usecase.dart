import '../../../../core/error/result.dart';
import '../entities/order.dart';
import '../entities/shipping_address.dart';
import '../repositories/order_repository.dart';

class CheckoutUseCase {
  const CheckoutUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<Order>> call({
    required ShippingAddress shippingAddress,
    String? customerNote,
    String? idempotencyKey,
  }) => _repository.checkout(
    shippingAddress: shippingAddress,
    customerNote: customerNote,
    idempotencyKey: idempotencyKey,
  );
}
