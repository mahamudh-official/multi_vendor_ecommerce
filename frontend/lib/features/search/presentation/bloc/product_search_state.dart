import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product.dart';
import '../../domain/entities/search_filter_params.dart';

enum ProductSearchStatus { initial, loading, loaded, loadingMore, empty, error }

class ProductSearchState extends Equatable {
  const ProductSearchState({
    this.status = ProductSearchStatus.initial,
    this.products = const [],
    this.params = const SearchFilterParams(),
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.errorMessage,
  });

  final ProductSearchStatus status;
  final List<Product> products;
  final SearchFilterParams params;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final String? errorMessage;

  bool get isLoading => status == ProductSearchStatus.loading;
  bool get isLoadingMore => status == ProductSearchStatus.loadingMore;
  bool get isEmpty => status == ProductSearchStatus.empty;
  bool get hasError => status == ProductSearchStatus.error;

  ProductSearchState copyWith({
    ProductSearchStatus? status,
    List<Product>? products,
    SearchFilterParams? params,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
    String? errorMessage,
  }) {
    return ProductSearchState(
      status: status ?? this.status,
      products: products ?? this.products,
      params: params ?? this.params,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    params,
    total,
    totalPages,
    hasNext,
    hasPrevious,
    errorMessage,
  ];
}
