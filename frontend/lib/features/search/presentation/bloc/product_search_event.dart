import 'package:equatable/equatable.dart';

sealed class ProductSearchEvent extends Equatable {
  const ProductSearchEvent();

  @override
  List<Object?> get props => [];
}

final class ProductSearchQueryChanged extends ProductSearchEvent {
  const ProductSearchQueryChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

final class ProductSearchFilterApplied extends ProductSearchEvent {
  const ProductSearchFilterApplied({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStockOnly,
    this.sort,
  });

  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? inStockOnly;
  final String? sort;

  @override
  List<Object?> get props => [
    categoryId,
    minPrice,
    maxPrice,
    minRating,
    inStockOnly,
    sort,
  ];
}

final class ProductSearchSortChanged extends ProductSearchEvent {
  const ProductSearchSortChanged(this.sort);
  final String sort;

  @override
  List<Object?> get props => [sort];
}

final class ProductSearchNextPageRequested extends ProductSearchEvent {
  const ProductSearchNextPageRequested();
}

final class ProductSearchCleared extends ProductSearchEvent {
  const ProductSearchCleared();
}

final class ProductSearchResetFilters extends ProductSearchEvent {
  const ProductSearchResetFilters();
}
