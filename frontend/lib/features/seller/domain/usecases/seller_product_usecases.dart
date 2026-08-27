import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_product.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/repositories/seller_repository.dart';

class GetSellerProductsUseCase {
  final SellerRepository repository;

  const GetSellerProductsUseCase(this.repository);

  Future<Result<List<SellerProduct>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String sort = 'newest',
  }) {
    return repository.getProducts(
      page: page,
      pageSize: pageSize,
      search: search,
      categoryId: categoryId,
      isActive: isActive,
      lowStock: lowStock,
      sort: sort,
    );
  }
}

class GetSellerProductUseCase {
  final SellerRepository repository;

  const GetSellerProductUseCase(this.repository);

  Future<Result<SellerProduct>> call(String id) {
    return repository.getProduct(id);
  }
}

class CreateSellerProductUseCase {
  final SellerRepository repository;

  const CreateSellerProductUseCase(this.repository);

  Future<Result<SellerProduct>> call({
    required String name,
    required double price,
    required int stockQuantity,
    required String categoryId,
    String? description,
    String? sku,
    String? imageUrl,
    bool isActive = true,
  }) {
    return repository.createProduct(
      name: name,
      price: price,
      stockQuantity: stockQuantity,
      categoryId: categoryId,
      description: description,
      sku: sku,
      imageUrl: imageUrl,
      isActive: isActive,
    );
  }
}

class UpdateSellerProductUseCase {
  final SellerRepository repository;

  const UpdateSellerProductUseCase(this.repository);

  Future<Result<SellerProduct>> call({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? categoryId,
    String? sku,
    String? imageUrl,
    bool? isActive,
  }) {
    return repository.updateProduct(
      id: id,
      name: name,
      description: description,
      price: price,
      stockQuantity: stockQuantity,
      categoryId: categoryId,
      sku: sku,
      imageUrl: imageUrl,
      isActive: isActive,
    );
  }
}

class DeactivateSellerProductUseCase {
  final SellerRepository repository;

  const DeactivateSellerProductUseCase(this.repository);

  Future<Result<void>> call(String id) {
    return repository.deactivateProduct(id);
  }
}
