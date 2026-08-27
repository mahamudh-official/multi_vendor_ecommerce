import 'package:equatable/equatable.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

final class ProductsRequested extends ProductEvent {
  const ProductsRequested({
    this.refresh = false,
    this.search,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.isFeatured,
    this.sort = 'newest',
  });

  final bool refresh;
  final String? search;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final bool? isFeatured;
  final String sort;

  @override
  List<Object?> get props => [
    refresh,
    search,
    categoryId,
    minPrice,
    maxPrice,
    isFeatured,
    sort,
  ];
}

final class ProductSearchChanged extends ProductEvent {
  const ProductSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ProductFilterApplied extends ProductEvent {
  const ProductFilterApplied({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sort = 'newest',
  });

  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String sort;

  @override
  List<Object?> get props => [categoryId, minPrice, maxPrice, sort];
}

final class ProductsLoadMore extends ProductEvent {
  const ProductsLoadMore();
}
