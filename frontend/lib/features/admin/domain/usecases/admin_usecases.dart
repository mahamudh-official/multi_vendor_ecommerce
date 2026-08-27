import '../../../../core/error/result.dart';
import '../entities/admin_entities.dart';
import '../repositories/admin_repository.dart';

class GetAdminDashboardStatsUseCase {
  final AdminRepository repository;
  GetAdminDashboardStatsUseCase(this.repository);

  Future<Result<AdminDashboardStats>> call() => repository.getDashboardStats();
}

class GetAdminUsersUseCase {
  final AdminRepository repository;
  GetAdminUsersUseCase(this.repository);

  Future<Result<List<AdminUser>>> call({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) => repository.getUsers(
    search: search,
    role: role,
    isActive: isActive,
    page: page,
    pageSize: pageSize,
  );
}

class UpdateAdminUserStatusUseCase {
  final AdminRepository repository;
  UpdateAdminUserStatusUseCase(this.repository);

  Future<Result<AdminUser>> call({
    required String userId,
    required bool isActive,
  }) => repository.updateUserStatus(userId: userId, isActive: isActive);
}

class GetAdminSellersUseCase {
  final AdminRepository repository;
  GetAdminSellersUseCase(this.repository);

  Future<Result<List<AdminSeller>>> call({
    String? search,
    String? sellerStatus,
    int page = 1,
    int pageSize = 20,
  }) => repository.getSellers(
    search: search,
    sellerStatus: sellerStatus,
    page: page,
    pageSize: pageSize,
  );
}

class UpdateAdminSellerStatusUseCase {
  final AdminRepository repository;
  UpdateAdminSellerStatusUseCase(this.repository);

  Future<Result<AdminSeller>> call({
    required String sellerId,
    required String status,
  }) => repository.updateSellerStatus(sellerId: sellerId, status: status);
}

class GetAdminProductsUseCase {
  final AdminRepository repository;
  GetAdminProductsUseCase(this.repository);

  Future<Result<List<AdminProduct>>> call({
    String? sellerId,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) => repository.getProducts(
    sellerId: sellerId,
    categoryId: categoryId,
    isActive: isActive,
    lowStock: lowStock,
    search: search,
    page: page,
    pageSize: pageSize,
  );
}

class UpdateAdminProductStatusUseCase {
  final AdminRepository repository;
  UpdateAdminProductStatusUseCase(this.repository);

  Future<Result<AdminProduct>> call({
    required String productId,
    required bool isActive,
  }) =>
      repository.updateProductStatus(productId: productId, isActive: isActive);
}

class GetAdminCategoriesUseCase {
  final AdminRepository repository;
  GetAdminCategoriesUseCase(this.repository);

  Future<Result<List<AdminCategory>>> call() => repository.getCategories();
}

class CreateAdminCategoryUseCase {
  final AdminRepository repository;
  CreateAdminCategoryUseCase(this.repository);

  Future<Result<AdminCategory>> call({
    required String name,
    String? slug,
    String? description,
    String? imageUrl,
    bool isActive = true,
  }) => repository.createCategory(
    name: name,
    slug: slug,
    description: description,
    imageUrl: imageUrl,
    isActive: isActive,
  );
}

class UpdateAdminCategoryUseCase {
  final AdminRepository repository;
  UpdateAdminCategoryUseCase(this.repository);

  Future<Result<AdminCategory>> call({
    required String categoryId,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) => repository.updateCategory(
    categoryId: categoryId,
    name: name,
    slug: slug,
    description: description,
    imageUrl: imageUrl,
    isActive: isActive,
  );
}

class DeleteAdminCategoryUseCase {
  final AdminRepository repository;
  DeleteAdminCategoryUseCase(this.repository);

  Future<Result<void>> call(String categoryId) =>
      repository.deleteCategory(categoryId);
}

class GetAdminOrdersUseCase {
  final AdminRepository repository;
  GetAdminOrdersUseCase(this.repository);

  Future<Result<List<AdminOrder>>> call({
    String? status,
    String? paymentStatus,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) => repository.getOrders(
    status: status,
    paymentStatus: paymentStatus,
    customerId: customerId,
    sellerId: sellerId,
    page: page,
    pageSize: pageSize,
  );
}

class GetAdminOrderDetailsUseCase {
  final AdminRepository repository;
  GetAdminOrderDetailsUseCase(this.repository);

  Future<Result<AdminOrder>> call(String orderId) =>
      repository.getOrderDetails(orderId);
}

class GetAdminPaymentsUseCase {
  final AdminRepository repository;
  GetAdminPaymentsUseCase(this.repository);

  Future<Result<List<AdminPayment>>> call({
    String? status,
    String? provider,
    int page = 1,
    int pageSize = 20,
  }) => repository.getPayments(
    status: status,
    provider: provider,
    page: page,
    pageSize: pageSize,
  );
}

class GetAdminAuditLogsUseCase {
  final AdminRepository repository;
  GetAdminAuditLogsUseCase(this.repository);

  Future<Result<List<AdminAuditLog>>> call({
    String? adminUserId,
    String? action,
    String? entityType,
    int page = 1,
    int pageSize = 20,
  }) => repository.getAuditLogs(
    adminUserId: adminUserId,
    action: action,
    entityType: entityType,
    page: page,
    pageSize: pageSize,
  );
}
