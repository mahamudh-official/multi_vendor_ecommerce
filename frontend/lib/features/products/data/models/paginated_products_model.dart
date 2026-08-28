import '../../domain/entities/paginated_products.dart';
import 'product_model.dart';

/// DTO for Paginated Products response.
class PaginatedProductsModel {
  const PaginatedProductsModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  factory PaginatedProductsModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return PaginatedProductsModel(
      items: itemsList
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }

  final List<ProductModel> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginatedProducts toEntity() {
    return PaginatedProducts(
      items: items.map((m) => m.toEntity()).toList(),
      page: page,
      pageSize: pageSize,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }
}
