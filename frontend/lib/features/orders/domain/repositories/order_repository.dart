import '../../../../core/error/result.dart';
import '../entities/order.dart';
import '../entities/order_status.dart';
import '../entities/shipping_address.dart';

abstract interface class OrderRepository {
  Future<Result<Order>> checkout({
    required ShippingAddress shippingAddress,
    String? customerNote,
    String? idempotencyKey,
  });

  Future<Result<List<Order>>> getOrders({
    OrderStatus? status,
    int page = 1,
    int pageSize = 10,
  });

  Future<Result<Order>> getOrderDetails(String orderId);

  Future<Result<void>> cancelOrder(String orderId);
}
