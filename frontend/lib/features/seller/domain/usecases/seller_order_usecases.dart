import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_order.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/repositories/seller_repository.dart';

class GetSellerOrdersUseCase {
  final SellerRepository repository;

  const GetSellerOrdersUseCase(this.repository);

  Future<Result<List<SellerOrder>>> call({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getOrders(
      status: status,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }
}

class GetSellerOrderDetailsUseCase {
  final SellerRepository repository;

  const GetSellerOrderDetailsUseCase(this.repository);

  Future<Result<SellerOrder>> call(String orderId) {
    return repository.getOrderDetails(orderId);
  }
}

class UpdateSellerOrderStatusUseCase {
  final SellerRepository repository;

  const UpdateSellerOrderStatusUseCase(this.repository);

  Future<Result<SellerOrder>> call({
    required String orderId,
    required FulfillmentStatus status,
  }) {
    return repository.updateOrderStatus(orderId: orderId, status: status);
  }
}
