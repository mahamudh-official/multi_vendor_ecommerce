import '../../../../core/error/result.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case for creating a new product listing (seller only).
class CreateProductUseCase {
  const CreateProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<Product>> call({
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
  }) {
    return _repository.createProduct(
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
  }
}
