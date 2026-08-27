import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_dashboard_stats.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_order.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_product.dart';

abstract interface class SellerRepository {
  Future<Result<SellerDashboard>> getDashboard();

  Future<Result<List<SellerProduct>>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String sort = 'newest',
  });

  Future<Result<SellerProduct>> getProduct(String id);

  Future<Result<SellerProduct>> createProduct({
    required String name,
    required double price,
    required int stockQuantity,
    required String categoryId,
    String? description,
    String? sku,
    String? imageUrl,
    bool isActive = true,
  });

  Future<Result<SellerProduct>> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? categoryId,
    String? sku,
    String? imageUrl,
    bool? isActive,
  });

  Future<Result<void>> deactivateProduct(String id);

  Future<Result<List<SellerOrder>>> getOrders({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<SellerOrder>> getOrderDetails(String orderId);

  Future<Result<SellerOrder>> updateOrderStatus({
    required String orderId,
    required FulfillmentStatus status,
  });
}
