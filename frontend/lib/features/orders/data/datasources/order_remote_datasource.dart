import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/shipping_address.dart';
import '../models/order_model.dart';
import '../models/shipping_address_model.dart';

abstract interface class OrderRemoteDataSource {
  Future<OrderModel> checkout({
    required ShippingAddress shippingAddress,
    String? customerNote,
    String? idempotencyKey,
  });

  Future<List<OrderModel>> getOrders({
    OrderStatus? status,
    String? search,
    String? sort,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 10,
  });

  Future<OrderModel> getOrderDetails(String orderId);

  Future<void> cancelOrder(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  const OrderRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<OrderModel> checkout({
    required ShippingAddress shippingAddress,
    String? customerNote,
    String? idempotencyKey,
  }) async {
    final payload = {
      'shipping_address': ShippingAddressModel.fromEntity(
        shippingAddress,
      ).toJson(),
      if (customerNote != null && customerNote.isNotEmpty)
        'customer_note': customerNote,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotency_key': idempotencyKey,
    };

    final response = await dioClient.post<Map<String, dynamic>>(
      '/orders/checkout',
      data: payload,
    );
    return OrderModel.fromJson(response.data!);
  }

  @override
  Future<List<OrderModel>> getOrders({
    OrderStatus? status,
    String? search,
    String? sort,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null) {
      queryParams['status'] = status.value;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (sort != null) {
      queryParams['sort'] = sort;
    }
    if (fromDate != null) {
      queryParams['from_date'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      queryParams['to_date'] = toDate.toIso8601String();
    }

    final response = await dioClient.get<Map<String, dynamic>>(
      '/orders',
      queryParameters: queryParams,
    );
    final data = response.data?['items'] as List<dynamic>? ?? [];
    return data
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> getOrderDetails(String orderId) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      '/orders/$orderId',
    );
    return OrderModel.fromJson(response.data!);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await dioClient.post<dynamic>('/orders/$orderId/cancel');
  }
}
