import 'package:equatable/equatable.dart';

/// Parameters for querying, filtering, and sorting products in search.
class SearchFilterParams extends Equatable {
  const SearchFilterParams({
    this.query,
    this.categoryId,
    this.sellerId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStockOnly,
    this.sort = 'newest',
    this.page = 1,
    this.pageSize = 20,
  });

  final String? query;
  final String? categoryId;
  final String? sellerId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? inStockOnly;
  final String sort;
  final int page;
  final int pageSize;

  bool get hasActiveFilters =>
      (categoryId != null && categoryId!.isNotEmpty) ||
      sellerId != null ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      inStockOnly == true ||
      sort != 'newest';

  int get activeFilterCount {
    int count = 0;
    if (categoryId != null && categoryId!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (inStockOnly == true) count++;
    if (sort != 'newest') count++;
    return count;
  }

  SearchFilterParams copyWith({
    String? query,
    bool clearQuery = false,
    String? categoryId,
    bool clearCategory = false,
    String? sellerId,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    double? minRating,
    bool clearMinRating = false,
    bool? inStockOnly,
    bool clearInStockOnly = false,
    String? sort,
    int? page,
    int? pageSize,
  }) {
    return SearchFilterParams(
      query: clearQuery ? null : (query ?? this.query),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      sellerId: sellerId ?? this.sellerId,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      inStockOnly: clearInStockOnly ? null : (inStockOnly ?? this.inStockOnly),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  SearchFilterParams resetFilters() {
    return SearchFilterParams(
      query: query,
      page: 1,
      pageSize: pageSize,
      sort: 'newest',
    );
  }

  @override
  List<Object?> get props => [
    query,
    categoryId,
    sellerId,
    minPrice,
    maxPrice,
    minRating,
    inStockOnly,
    sort,
    page,
    pageSize,
  ];
}
