import '../../domain/entities/product_image.dart';
import '../../domain/entities/seller_summary.dart';

/// DTO for seller public summary.
class SellerSummaryModel {
  const SellerSummaryModel({required this.id, required this.fullName});

  factory SellerSummaryModel.fromJson(Map<String, dynamic> json) {
    return SellerSummaryModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Marketplace Seller',
    );
  }

  final String id;
  final String fullName;

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': fullName};
  }

  SellerSummary toEntity() => SellerSummary(id: id, fullName: fullName);
}

/// DTO for product auxiliary image.
class ProductImageModel {
  const ProductImageModel({
    required this.id,
    required this.imageUrl,
    this.sortOrder = 0,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  final String id;
  final String imageUrl;
  final int sortOrder;

  Map<String, dynamic> toJson() {
    return {'id': id, 'image_url': imageUrl, 'sort_order': sortOrder};
  }

  ProductImage toEntity() =>
      ProductImage(id: id, imageUrl: imageUrl, sortOrder: sortOrder);
}
