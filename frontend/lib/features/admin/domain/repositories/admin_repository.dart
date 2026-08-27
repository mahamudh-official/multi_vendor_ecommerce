import '../../../../core/error/result.dart';
import '../entities/admin_entities.dart';

abstract class AdminRepository {
  Future<Result<AdminDashboardStats>> getDashboardStats();

  Future<Result<List<AdminUser>>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<AdminUser>> updateUserStatus({
    required String userId,
    required bool isActive,
  });

  Future<Result<List<AdminSeller>>> getSellers({
    String? search,
    String? sellerStatus,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<AdminSeller>> updateSellerStatus({
    required String sellerId,
    required String status,
  });

  Future<Result<List<AdminProduct>>> getProducts({
    String? sellerId,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<AdminProduct>> updateProductStatus({
    required String productId,
    required bool isActive,
  });

  Future<Result<List<AdminCategory>>> getCategories();

  Future<Result<AdminCategory>> createCategory({
    required String name,
    String? slug,
    String? description,
    String? imageUrl,
    bool isActive = true,
  });

  Future<Result<AdminCategory>> updateCategory({
    required String categoryId,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    bool? isActive,
  });

  Future<Result<void>> deleteCategory(String categoryId);

  Future<Result<List<AdminOrder>>> getOrders({
    String? status,
    String? paymentStatus,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<AdminOrder>> getOrderDetails(String orderId);

  Future<Result<List<AdminPayment>>> getPayments({
    String? status,
    String? provider,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<List<AdminAuditLog>>> getAuditLogs({
    String? adminUserId,
    String? action,
    String? entityType,
    int page = 1,
    int pageSize = 20,
  });
}
