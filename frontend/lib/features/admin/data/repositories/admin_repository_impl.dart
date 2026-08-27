import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  Failure _handleError(dynamic error) {
    if (error is DioException) {
      final msg =
          error.response?.data?['detail']?.toString() ??
          error.message ??
          'An unexpected error occurred.';
      return ServerFailure(message: msg);
    }
    return ServerFailure(message: error.toString());
  }

  @override
  Future<Result<AdminDashboardStats>> getDashboardStats() async {
    try {
      final stats = await remoteDataSource.getDashboardStats();
      return Success(stats);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<List<AdminUser>>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final users = await remoteDataSource.getUsers(
        search: search,
        role: role,
        isActive: isActive,
        page: page,
        pageSize: pageSize,
      );
      return Success(users);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<AdminUser>> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      final user = await remoteDataSource.updateUserStatus(
        userId: userId,
        isActive: isActive,
      );
      return Success(user);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<List<AdminSeller>>> getSellers({
    String? search,
    String? sellerStatus,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final sellers = await remoteDataSource.getSellers(
        search: search,
        sellerStatus: sellerStatus,
        page: page,
        pageSize: pageSize,
      );
      return Success(sellers);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<AdminSeller>> updateSellerStatus({
    required String sellerId,
    required String status,
  }) async {
    try {
      final seller = await remoteDataSource.updateSellerStatus(
        sellerId: sellerId,
        status: status,
      );
      return Success(seller);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<List<AdminProduct>>> getProducts({
    String? sellerId,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final products = await remoteDataSource.getProducts(
        sellerId: sellerId,
        categoryId: categoryId,
        isActive: isActive,
        lowStock: lowStock,
        search: search,
        page: page,
        pageSize: pageSize,
      );
      return Success(products);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<AdminProduct>> updateProductStatus({
    required String productId,
    required bool isActive,
  }) async {
    try {
      final product = await remoteDataSource.updateProductStatus(
        productId: productId,
        isActive: isActive,
      );
      return Success(product);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<List<AdminCategory>>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      return Success(categories);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<AdminCategory>> createCategory({
    required String name,
    String? slug,
    String? description,
    String? imageUrl,
    bool isActive = true,
  }) async {
    try {
      final category = await remoteDataSource.createCategory(
        name: name,
        slug: slug,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive,
      );
      return Success(category);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<AdminCategory>> updateCategory({
    required String categoryId,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      final category = await remoteDataSource.updateCategory(
        categoryId: categoryId,
        name: name,
        slug: slug,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive,
      );
      return Success(category);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<void>> deleteCategory(String categoryId) async {
    try {
      await remoteDataSource.deleteCategory(categoryId);
      return const Success(null);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<List<AdminOrder>>> getOrders({
    String? status,
    String? paymentStatus,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final orders = await remoteDataSource.getOrders(
        status: status,
        paymentStatus: paymentStatus,
        customerId: customerId,
        sellerId: sellerId,
        page: page,
        pageSize: pageSize,
      );
      return Success(orders);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<AdminOrder>> getOrderDetails(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderDetails(orderId);
      return Success(order);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<List<AdminPayment>>> getPayments({
    String? status,
    String? provider,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final payments = await remoteDataSource.getPayments(
        status: status,
        provider: provider,
        page: page,
        pageSize: pageSize,
      );
      return Success(payments);
    } catch (e) {
      return Error(_handleError(e));
    }
  }

  @override
  Future<Result<List<AdminAuditLog>>> getAuditLogs({
    String? adminUserId,
    String? action,
    String? entityType,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final logs = await remoteDataSource.getAuditLogs(
        adminUserId: adminUserId,
        action: action,
        entityType: entityType,
        page: page,
        pageSize: pageSize,
      );
      return Success(logs);
    } catch (e) {
      return Error(_handleError(e));
    }
  }
}
