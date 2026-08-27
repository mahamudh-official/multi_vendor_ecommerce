import '../../../../core/error/result.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case for updating an existing product.
class UpdateProductUseCase {
  const UpdateProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<Product>> call({
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
  }) {
    return _repository.updateProduct(
      id: id,
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
  }
}
