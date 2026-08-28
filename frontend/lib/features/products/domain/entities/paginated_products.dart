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
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final List<Product> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  bool get hasMore => hasNext || page < totalPages;

  @override
  List<Object?> get props => [
    items,
    page,
    pageSize,
    total,
    totalPages,
    hasNext,
    hasPrevious,
  ];
}
