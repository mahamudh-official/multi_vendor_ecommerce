import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/paginated_products.dart';
import '../../../domain/usecases/get_products_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

/// BLoC managing product catalog queries, search, filtering, and pagination.
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({required this.getProductsUseCase})
    : super(const ProductInitial()) {
    on<ProductsRequested>(_onProductsRequested);
    on<ProductSearchChanged>(_onProductSearchChanged);
    on<ProductFilterApplied>(_onProductFilterApplied);
    on<ProductsLoadMore>(_onProductsLoadMore);
  }

  final GetProductsUseCase getProductsUseCase;

  Future<void> _onProductsRequested(
    ProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (!event.refresh && state is! ProductsLoaded) {
      emit(const ProductLoading());
    }

    final result = await getProductsUseCase(
      page: 1,
      pageSize: 20,
      search: event.search,
      categoryId: event.categoryId,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      isFeatured: event.isFeatured,
      sort: event.sort,
    );

    result.fold(
      onSuccess: (data) => emit(
        ProductsLoaded(
          data: data,
          search: event.search,
          categoryId: event.categoryId,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
          isFeatured: event.isFeatured,
          sort: event.sort,
        ),
      ),
      onError: (failure) => emit(ProductFailure(failure.message)),
    );
  }

  Future<void> _onProductSearchChanged(
    ProductSearchChanged event,
    Emitter<ProductState> emit,
  ) async {
    String? currentCatId;
    String currentSort = 'newest';
    if (state is ProductsLoaded) {
      final current = state as ProductsLoaded;
      currentCatId = current.categoryId;
      currentSort = current.sort;
    }

    emit(const ProductLoading());

    final result = await getProductsUseCase(
      page: 1,
      pageSize: 20,
      search: event.query.isNotEmpty ? event.query : null,
      categoryId: currentCatId,
      sort: currentSort,
    );

    result.fold(
      onSuccess: (data) => emit(
        ProductsLoaded(
          data: data,
          search: event.query.isNotEmpty ? event.query : null,
          categoryId: currentCatId,
          sort: currentSort,
        ),
      ),
      onError: (failure) => emit(ProductFailure(failure.message)),
    );
  }

  Future<void> _onProductFilterApplied(
    ProductFilterApplied event,
    Emitter<ProductState> emit,
  ) async {
    String? currentSearch;
    if (state is ProductsLoaded) {
      currentSearch = (state as ProductsLoaded).search;
    }

    emit(const ProductLoading());

    final result = await getProductsUseCase(
      page: 1,
      pageSize: 20,
      search: currentSearch,
      categoryId: event.categoryId,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      sort: event.sort,
    );

    result.fold(
      onSuccess: (data) => emit(
        ProductsLoaded(
          data: data,
          search: currentSearch,
          categoryId: event.categoryId,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
          sort: event.sort,
        ),
      ),
      onError: (failure) => emit(ProductFailure(failure.message)),
    );
  }

  Future<void> _onProductsLoadMore(
    ProductsLoadMore event,
    Emitter<ProductState> emit,
  ) async {
    if (state is! ProductsLoaded) return;
    final current = state as ProductsLoaded;
    if (!current.data.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.data.page + 1;
    final result = await getProductsUseCase(
      page: nextPage,
      pageSize: current.data.pageSize,
      search: current.search,
      categoryId: current.categoryId,
      minPrice: current.minPrice,
      maxPrice: current.maxPrice,
      isFeatured: current.isFeatured,
      sort: current.sort,
    );

    result.fold(
      onSuccess: (newData) {
        final combinedItems = List.of(current.data.items)
          ..addAll(newData.items);
        final combinedData = PaginatedProducts(
          items: combinedItems,
          page: newData.page,
          pageSize: newData.pageSize,
          total: newData.total,
          totalPages: newData.totalPages,
        );
        emit(current.copyWith(data: combinedData, isLoadingMore: false));
      },
      onError: (failure) {
        emit(current.copyWith(isLoadingMore: false));
      },
    );
  }
}
