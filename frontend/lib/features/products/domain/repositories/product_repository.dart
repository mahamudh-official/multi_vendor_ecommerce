import '../../../../core/error/result.dart';
import '../entities/paginated_products.dart';
import '../entities/product.dart';

/// Abstract contract for product catalog and seller operations.
abstract interface class ProductRepository {
  Future<Result<PaginatedProducts>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    String? sellerId,
    double? minPrice,
    double? maxPrice,
    bool? isFeatured,
    String sort = 'newest',
  });

  Future<Result<Product>> getProductDetails(String id);

  Future<Result<Product>> createProduct({
    required String name,
    String? description,
    required double price,
    double? compareAtPrice,
    int stockQuantity = 0,
    String? sku,
    required String categoryId,
    String? imageUrl,
    List<String> images = const [],
    bool isFeatured = false,
  });

  Future<Result<Product>> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    double? compareAtPrice,
    int? stockQuantity,
    String? sku,
    String? categoryId,
    String? imageUrl,
    List<String>? images,
    bool? isFeatured,
    bool? isActive,
  });

  Future<Result<void>> deleteProduct(String id);
}
