import 'package:equatable/equatable.dart';

/// Product auxiliary image entity.
class ProductImage extends Equatable {
  const ProductImage({
    required this.id,
    required this.imageUrl,
    this.sortOrder = 0,
  });

  final String id;
  final String imageUrl;
  final int sortOrder;

  @override
  List<Object?> get props => [id, imageUrl, sortOrder];
}
