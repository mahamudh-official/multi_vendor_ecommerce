import '../../../../core/error/result.dart';
import '../entities/paginated_products.dart';
import '../repositories/product_repository.dart';

/// Use case for searching, filtering, and paginating products.
class GetProductsUseCase {
  const GetProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<PaginatedProducts>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    String? sellerId,
    double? minPrice,
    double? maxPrice,
    bool? isFeatured,
    String sort = 'newest',
  }) {
    return _repository.getProducts(
      page: page,
      pageSize: pageSize,
      search: search,
      categoryId: categoryId,
      sellerId: sellerId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      isFeatured: isFeatured,
      sort: sort,
    );
  }
}
