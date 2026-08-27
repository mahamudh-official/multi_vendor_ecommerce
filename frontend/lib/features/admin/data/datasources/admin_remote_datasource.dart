import 'package:dio/dio.dart';

import '../models/admin_models.dart';

abstract class AdminRemoteDataSource {
  Future<AdminDashboardStatsModel> getDashboardStats();

  Future<List<AdminUserModel>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  });

  Future<AdminUserModel> updateUserStatus({
    required String userId,
    required bool isActive,
  });

  Future<List<AdminSellerModel>> getSellers({
    String? search,
    String? sellerStatus,
    int page = 1,
    int pageSize = 20,
  });

  Future<AdminSellerModel> updateSellerStatus({
    required String sellerId,
    required String status,
  });

  Future<List<AdminProductModel>> getProducts({
    String? sellerId,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<AdminProductModel> updateProductStatus({
    required String productId,
    required bool isActive,
  });

  Future<List<AdminCategoryModel>> getCategories();

  Future<AdminCategoryModel> createCategory({
    required String name,
    String? slug,
    String? description,
    String? imageUrl,
    bool isActive = true,
  });

  Future<AdminCategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    bool? isActive,
  });

  Future<void> deleteCategory(String categoryId);

  Future<List<AdminOrderModel>> getOrders({
    String? status,
    String? paymentStatus,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  });

  Future<AdminOrderModel> getOrderDetails(String orderId);

  Future<List<AdminPaymentModel>> getPayments({
    String? status,
    String? provider,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<AdminAuditLogModel>> getAuditLogs({
    String? adminUserId,
    String? action,
    String? entityType,
    int page = 1,
    int pageSize = 20,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({required this.dio});

  @override
  Future<AdminDashboardStatsModel> getDashboardStats() async {
    final response = await dio.get('/admin/dashboard');
    return AdminDashboardStatsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<AdminUserModel>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (role != null && role.isNotEmpty) query['role'] = role;
    if (isActive != null) query['is_active'] = isActive;

    final response = await dio.get('/admin/users', queryParameters: query);
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => AdminUserModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminUserModel> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    final response = await dio.patch(
      '/admin/users/$userId/status',
      data: {'is_active': isActive},
    );
    return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<AdminSellerModel>> getSellers({
    String? search,
    String? sellerStatus,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (sellerStatus != null && sellerStatus.isNotEmpty)
      query['seller_status'] = sellerStatus;

    final response = await dio.get('/admin/sellers', queryParameters: query);
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => AdminSellerModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminSellerModel> updateSellerStatus({
    required String sellerId,
    required String status,
  }) async {
    final response = await dio.patch(
      '/admin/sellers/$sellerId/status',
      data: {'status': status},
    );
    return AdminSellerModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<AdminProductModel>> getProducts({
    String? sellerId,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (sellerId != null) query['seller_id'] = sellerId;
    if (categoryId != null) query['category_id'] = categoryId;
    if (isActive != null) query['is_active'] = isActive;
    if (lowStock != null) query['low_stock'] = lowStock;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await dio.get('/admin/products', queryParameters: query);
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => AdminProductModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminProductModel> updateProductStatus({
    required String productId,
    required bool isActive,
  }) async {
    final response = await dio.patch(
      '/admin/products/$productId/status',
      data: {'is_active': isActive},
    );
    return AdminProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<AdminCategoryModel>> getCategories() async {
    final response = await dio.get('/admin/categories');
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => AdminCategoryModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminCategoryModel> createCategory({
    required String name,
    String? slug,
    String? description,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final payload = <String, dynamic>{'name': name, 'is_active': isActive};
    if (slug != null) payload['slug'] = slug;
    if (description != null) payload['description'] = description;
    if (imageUrl != null) payload['image_url'] = imageUrl;

    final response = await dio.post('/admin/categories', data: payload);
    return AdminCategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminCategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (slug != null) payload['slug'] = slug;
    if (description != null) payload['description'] = description;
    if (imageUrl != null) payload['image_url'] = imageUrl;
    if (isActive != null) payload['is_active'] = isActive;

    final response = await dio.patch(
      '/admin/categories/$categoryId',
      data: payload,
    );
    return AdminCategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await dio.delete('/admin/categories/$categoryId');
  }

  @override
  Future<List<AdminOrderModel>> getOrders({
    String? status,
    String? paymentStatus,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null) query['status'] = status;
    if (paymentStatus != null) query['payment_status'] = paymentStatus;
    if (customerId != null) query['customer_id'] = customerId;
    if (sellerId != null) query['seller_id'] = sellerId;

    final response = await dio.get('/admin/orders', queryParameters: query);
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => AdminOrderModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminOrderModel> getOrderDetails(String orderId) async {
    final response = await dio.get('/admin/orders/$orderId');
    return AdminOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<AdminPaymentModel>> getPayments({
    String? status,
    String? provider,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null) query['status'] = status;
    if (provider != null) query['provider'] = provider;

    final response = await dio.get('/admin/payments', queryParameters: query);
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => AdminPaymentModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AdminAuditLogModel>> getAuditLogs({
    String? adminUserId,
    String? action,
    String? entityType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (adminUserId != null) query['admin_user_id'] = adminUserId;
    if (action != null) query['action'] = action;
    if (entityType != null) query['entity_type'] = entityType;

    final response = await dio.get('/admin/audit-logs', queryParameters: query);
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => AdminAuditLogModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }
}
