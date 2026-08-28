import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/usecases/get_products_usecase.dart';
import 'product_search_event.dart';
import 'product_search_state.dart';

class ProductSearchBloc extends Bloc<ProductSearchEvent, ProductSearchState> {
  ProductSearchBloc({required this.getProductsUseCase})
    : super(const ProductSearchState()) {
    on<ProductSearchQueryChanged>(_onQueryChanged);
    on<ProductSearchFilterApplied>(_onFilterApplied);
    on<ProductSearchSortChanged>(_onSortChanged);
    on<ProductSearchNextPageRequested>(_onNextPageRequested);
    on<ProductSearchCleared>(_onCleared);
    on<ProductSearchResetFilters>(_onResetFilters);
  }

  final GetProductsUseCase getProductsUseCase;
  Timer? _debounceTimer;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  void _onQueryChanged(
    ProductSearchQueryChanged event,
    Emitter<ProductSearchState> emit,
  ) {
    _debounceTimer?.cancel();
    final completer = Completer<void>();

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final updatedParams = state.params.copyWith(
        query: event.query.trim(),
        page: 1,
      );
      await _executeSearch(updatedParams, emit, isNewQuery: true);
      completer.complete();
    });
  }

  Future<void> _onFilterApplied(
    ProductSearchFilterApplied event,
    Emitter<ProductSearchState> emit,
  ) async {
    final updatedParams = state.params.copyWith(
      categoryId: event.categoryId,
      clearCategory: event.categoryId == null,
      minPrice: event.minPrice,
      clearMinPrice: event.minPrice == null,
      maxPrice: event.maxPrice,
      clearMaxPrice: event.maxPrice == null,
      minRating: event.minRating,
      clearMinRating: event.minRating == null,
      inStockOnly: event.inStockOnly,
      clearInStockOnly: event.inStockOnly == null,
      sort: event.sort ?? state.params.sort,
      page: 1,
    );
    await _executeSearch(updatedParams, emit, isNewQuery: true);
  }

  Future<void> _onSortChanged(
    ProductSearchSortChanged event,
    Emitter<ProductSearchState> emit,
  ) async {
    final updatedParams = state.params.copyWith(sort: event.sort, page: 1);
    await _executeSearch(updatedParams, emit, isNewQuery: true);
  }

  Future<void> _onNextPageRequested(
    ProductSearchNextPageRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    if (!state.hasNext || state.isLoadingMore || state.isLoading) return;

    final nextPage = state.params.page + 1;
    final updatedParams = state.params.copyWith(page: nextPage);

    emit(state.copyWith(status: ProductSearchStatus.loadingMore));

    final result = await getProductsUseCase(
      page: updatedParams.page,
      pageSize: updatedParams.pageSize,
      search: updatedParams.query,
      categoryId: updatedParams.categoryId,
      sellerId: updatedParams.sellerId,
      minPrice: updatedParams.minPrice,
      maxPrice: updatedParams.maxPrice,
      minRating: updatedParams.minRating,
      inStock: updatedParams.inStockOnly,
      sort: updatedParams.sort,
    );

    result.fold(
      onSuccess: (paginated) {
        final combined = [...state.products, ...paginated.items];
        emit(
          state.copyWith(
            status: ProductSearchStatus.loaded,
            products: combined,
            params: updatedParams,
            total: paginated.total,
            totalPages: paginated.totalPages,
            hasNext: paginated.hasNext,
            hasPrevious: paginated.hasPrevious,
          ),
        );
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: ProductSearchStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> _onCleared(
    ProductSearchCleared event,
    Emitter<ProductSearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    final updatedParams = state.params.copyWith(clearQuery: true, page: 1);
    await _executeSearch(updatedParams, emit, isNewQuery: true);
  }

  Future<void> _onResetFilters(
    ProductSearchResetFilters event,
    Emitter<ProductSearchState> emit,
  ) async {
    final updatedParams = state.params.resetFilters();
    await _executeSearch(updatedParams, emit, isNewQuery: true);
  }

  Future<void> _executeSearch(
    dynamic updatedParams,
    Emitter<ProductSearchState> emit, {
    bool isNewQuery = false,
  }) async {
    emit(
      state.copyWith(
        status: ProductSearchStatus.loading,
        params: updatedParams,
        products: isNewQuery ? [] : state.products,
      ),
    );

    final result = await getProductsUseCase(
      page: updatedParams.page,
      pageSize: updatedParams.pageSize,
      search: updatedParams.query,
      categoryId: updatedParams.categoryId,
      sellerId: updatedParams.sellerId,
      minPrice: updatedParams.minPrice,
      maxPrice: updatedParams.maxPrice,
      minRating: updatedParams.minRating,
      inStock: updatedParams.inStockOnly,
      sort: updatedParams.sort,
    );

    result.fold(
      onSuccess: (paginated) {
        if (paginated.items.isEmpty) {
          emit(
            state.copyWith(
              status: ProductSearchStatus.empty,
              products: [],
              params: updatedParams,
              total: 0,
              totalPages: 0,
              hasNext: false,
              hasPrevious: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: ProductSearchStatus.loaded,
              products: paginated.items,
              params: updatedParams,
              total: paginated.total,
              totalPages: paginated.totalPages,
              hasNext: paginated.hasNext,
              hasPrevious: paginated.hasPrevious,
            ),
          );
        }
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: ProductSearchStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }
}
