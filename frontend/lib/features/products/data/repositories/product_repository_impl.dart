import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/paginated_products.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_request_models.dart';

/// Implementation of ProductRepository with Result envelope and failure mapping.
class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<Result<PaginatedProducts>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    String? sellerId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStock,
    bool? isFeatured,
    String sort = 'newest',
  }) async {
    try {
      final model = await _remoteDataSource.getProducts(
        page: page,
        pageSize: pageSize,
        search: search,
        categoryId: categoryId,
        sellerId: sellerId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        inStock: inStock,
        isFeatured: isFeatured,
        sort: sort,
      );
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Product>> getProductDetails(String id) async {
    try {
      final model = await _remoteDataSource.getProductDetails(id);
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final request = ProductCreateRequestModel(
        name: name,
        description: description,
        price: price,
        compareAtPrice: compareAtPrice,
        stockQuantity: stockQuantity,
        sku: sku,
        categoryId: categoryId,
        imageUrl: imageUrl,
        images: images,
        isFeatured: isFeatured,
      );
      final model = await _remoteDataSource.createProduct(request);
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final request = ProductUpdateRequestModel(
        name: name,
        description: description,
        price: price,
        compareAtPrice: compareAtPrice,
        stockQuantity: stockQuantity,
        sku: sku,
        categoryId: categoryId,
        imageUrl: imageUrl,
        images: images,
        isFeatured: isFeatured,
        isActive: isActive,
      );
      final model = await _remoteDataSource.updateProduct(id, request);
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProduct(String id) async {
    try {
      await _remoteDataSource.deleteProduct(id);
      return const Success(null);
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
