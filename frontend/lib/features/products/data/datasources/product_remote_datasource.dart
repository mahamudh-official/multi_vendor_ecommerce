import '../../../../core/network/dio_client.dart';
import '../models/paginated_products_model.dart';
import '../models/product_model.dart';
import '../models/product_request_models.dart';

/// Contract for product remote data interactions.
abstract interface class ProductRemoteDataSource {
  Future<PaginatedProductsModel> getProducts({
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
  });

  Future<ProductModel> getProductDetails(String id);

  Future<ProductModel> createProduct(ProductCreateRequestModel request);

  Future<ProductModel> updateProduct(
    String id,
    ProductUpdateRequestModel request,
  );

  Future<void> deleteProduct(String id);
}

/// Dio implementation for ProductRemoteDataSource.
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  const ProductRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<PaginatedProductsModel> getProducts({
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
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort': sort,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['category_id'] = categoryId;
    }
    if (sellerId != null && sellerId.isNotEmpty) {
      queryParams['seller_id'] = sellerId;
    }
    if (minPrice != null) {
      queryParams['min_price'] = minPrice;
    }
    if (maxPrice != null) {
      queryParams['max_price'] = maxPrice;
    }
    if (minRating != null) {
      queryParams['min_rating'] = minRating;
    }
    if (inStock != null) {
      queryParams['in_stock'] = inStock;
    }
    if (isFeatured != null) {
      queryParams['is_featured'] = isFeatured;
    }

    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/products',
      queryParameters: queryParams,
    );

    return PaginatedProductsModel.fromJson(response.data!);
  }

  @override
  Future<ProductModel> getProductDetails(String id) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/products/$id',
    );
    return ProductModel.fromJson(response.data!);
  }

  @override
  Future<ProductModel> createProduct(ProductCreateRequestModel request) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/api/v1/products',
      data: request.toJson(),
    );
    return ProductModel.fromJson(response.data!);
  }

  @override
  Future<ProductModel> updateProduct(
    String id,
    ProductUpdateRequestModel request,
  ) async {
    final response = await _dioClient.patch<Map<String, dynamic>>(
      '/api/v1/products/$id',
      data: request.toJson(),
    );
    return ProductModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _dioClient.delete<dynamic>('/api/v1/products/$id');
  }
}
