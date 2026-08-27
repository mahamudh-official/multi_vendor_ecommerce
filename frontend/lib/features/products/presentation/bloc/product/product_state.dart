import 'package:equatable/equatable.dart';

import '../../../domain/entities/paginated_products.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

final class ProductInitial extends ProductState {
  const ProductInitial();
}

final class ProductLoading extends ProductState {
  const ProductLoading();
}

final class ProductsLoaded extends ProductState {
  const ProductsLoaded({
    required this.data,
    this.search,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.isFeatured,
    this.sort = 'newest',
    this.isLoadingMore = false,
  });

  final PaginatedProducts data;
  final String? search;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final bool? isFeatured;
  final String sort;
  final bool isLoadingMore;

  ProductsLoaded copyWith({
    PaginatedProducts? data,
    String? Function()? search,
    String? Function()? categoryId,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    bool? Function()? isFeatured,
    String? sort,
    bool? isLoadingMore,
  }) {
    return ProductsLoaded(
      data: data ?? this.data,
      search: search != null ? search() : this.search,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      isFeatured: isFeatured != null ? isFeatured() : this.isFeatured,
      sort: sort ?? this.sort,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    data,
    search,
    categoryId,
    minPrice,
    maxPrice,
    isFeatured,
    sort,
    isLoadingMore,
  ];
}

final class ProductFailure extends ProductState {
  const ProductFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
