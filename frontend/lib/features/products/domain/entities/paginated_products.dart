import 'package:equatable/equatable.dart';

import 'product.dart';

/// Paginated products result envelope.
class PaginatedProducts extends Equatable {
  const PaginatedProducts({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<Product> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, pageSize, total, totalPages];
}
