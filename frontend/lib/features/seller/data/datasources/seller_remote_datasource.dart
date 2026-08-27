import 'package:multi_vendor_ecommerce/core/network/dio_client.dart';
import 'package:multi_vendor_ecommerce/features/seller/data/models/seller_dashboard_model.dart';
import 'package:multi_vendor_ecommerce/features/seller/data/models/seller_order_model.dart';
import 'package:multi_vendor_ecommerce/features/seller/data/models/seller_product_model.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';

abstract class SellerRemoteDataSource {
  Future<SellerDashboardModel> getDashboard();

  Future<List<SellerProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String sort = 'newest',
  });

  Future<SellerProductModel> getProduct(String id);

  Future<SellerProductModel> createProduct({
    required String name,
    required double price,
    required int stockQuantity,
    required String categoryId,
    String? description,
    String? sku,
    String? imageUrl,
    bool isActive = true,
  });

  Future<SellerProductModel> updateProduct({
    required String id,
    String? name,
    double? price,
    int? stockQuantity,
    String? categoryId,
    String? description,
    String? sku,
    String? imageUrl,
    bool? isActive,
  });

  Future<void> deactivateProduct(String id);

  Future<List<SellerOrderModel>> getOrders({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<SellerOrderModel> getOrderDetails(String orderId);

  Future<SellerOrderModel> updateOrderStatus({
    required String orderId,
    required FulfillmentStatus status,
  });
}

class SellerRemoteDataSourceImpl implements SellerRemoteDataSource {
  final DioClient dioClient;

  const SellerRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<SellerDashboardModel> getDashboard() async {
    final response = await dioClient.get('/seller/dashboard');
    return SellerDashboardModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<SellerProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String sort = 'newest',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort': sort,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['category_id'] = categoryId;
    }
    if (isActive != null) queryParams['is_active'] = isActive;
    if (lowStock != null) queryParams['low_stock'] = lowStock;

    final response = await dioClient.get(
      '/seller/products',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((p) => SellerProductModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SellerProductModel> getProduct(String id) async {
    final response = await dioClient.get('/seller/products/$id');
    return SellerProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SellerProductModel> createProduct({
    required String name,
    required double price,
    required int stockQuantity,
    required String categoryId,
    String? description,
    String? sku,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'is_active': isActive,
    };
    if (description != null) payload['description'] = description;
    if (sku != null) payload['sku'] = sku;
    if (imageUrl != null) payload['image_url'] = imageUrl;

    final response = await dioClient.post(
      '/seller/products',
      data: payload,
    );

    return SellerProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SellerProductModel> updateProduct({
    required String id,
    String? name,
    double? price,
    int? stockQuantity,
    String? categoryId,
    String? description,
    String? sku,
    String? imageUrl,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (price != null) payload['price'] = price;
    if (stockQuantity != null) payload['stock_quantity'] = stockQuantity;
    if (categoryId != null) payload['category_id'] = categoryId;
    if (description != null) payload['description'] = description;
    if (sku != null) payload['sku'] = sku;
    if (imageUrl != null) payload['image_url'] = imageUrl;
    if (isActive != null) payload['is_active'] = isActive;

    final response = await dioClient.put(
      '/seller/products/$id',
      data: payload,
    );

    return SellerProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deactivateProduct(String id) async {
    await dioClient.delete('/seller/products/$id');
  }

  @override
  Future<List<SellerOrderModel>> getOrders({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await dioClient.get(
      '/seller/orders',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((o) => SellerOrderModel.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SellerOrderModel> getOrderDetails(String orderId) async {
    final response = await dioClient.get('/seller/orders/$orderId');
    return SellerOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SellerOrderModel> updateOrderStatus({
    required String orderId,
    required FulfillmentStatus status,
  }) async {
    final response = await dioClient.patch(
      '/seller/orders/$orderId/status',
      data: {'status': status.name},
    );

    final data = response.data as Map<String, dynamic>;
    final orderJson = data['order'] as Map<String, dynamic>;
    return SellerOrderModel.fromJson(orderJson);
  }
}
