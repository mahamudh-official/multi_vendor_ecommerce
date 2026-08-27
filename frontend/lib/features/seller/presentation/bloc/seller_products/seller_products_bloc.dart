import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_product.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/usecases/seller_product_usecases.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class SellerProductsEvent extends Equatable {
  const SellerProductsEvent();

  @override
  List<Object?> get props => [];
}

class SellerProductsRequested extends SellerProductsEvent {
  final int page;
  final int pageSize;
  final String? search;
  final String? categoryId;
  final bool? isActive;
  final bool? lowStock;
  final String sort;

  const SellerProductsRequested({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.categoryId,
    this.isActive,
    this.lowStock,
    this.sort = 'newest',
  });

  @override
  List<Object?> get props => [
    page,
    pageSize,
    search,
    categoryId,
    isActive,
    lowStock,
    sort,
  ];
}

class SellerProductDetailsRequested extends SellerProductsEvent {
  final String productId;

  const SellerProductDetailsRequested({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class SellerProductCreated extends SellerProductsEvent {
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String categoryId;
  final String? sku;
  final String? imageUrl;
  final bool isActive;

  const SellerProductCreated({
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    required this.categoryId,
    this.sku,
    this.imageUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    name,
    description,
    price,
    stockQuantity,
    categoryId,
    sku,
    imageUrl,
    isActive,
  ];
}

class SellerProductUpdated extends SellerProductsEvent {
  final String productId;
  final String? name;
  final String? description;
  final double? price;
  final int? stockQuantity;
  final String? categoryId;
  final String? sku;
  final String? imageUrl;
  final bool? isActive;

  const SellerProductUpdated({
    required this.productId,
    this.name,
    this.description,
    this.price,
    this.stockQuantity,
    this.categoryId,
    this.sku,
    this.imageUrl,
    this.isActive,
  });

  @override
  List<Object?> get props => [
    productId,
    name,
    description,
    price,
    stockQuantity,
    categoryId,
    sku,
    imageUrl,
    isActive,
  ];
}

class SellerProductDeactivated extends SellerProductsEvent {
  final String productId;

  const SellerProductDeactivated({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class SellerProductsReset extends SellerProductsEvent {
  const SellerProductsReset();
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class SellerProductsState extends Equatable {
  const SellerProductsState();

  @override
  List<Object?> get props => [];
}

class SellerProductsInitial extends SellerProductsState {
  const SellerProductsInitial();
}

class SellerProductsLoading extends SellerProductsState {
  const SellerProductsLoading();
}

class SellerProductsLoaded extends SellerProductsState {
  final List<SellerProduct> products;
  final int page;
  final bool hasMore;

  const SellerProductsLoaded({
    required this.products,
    this.page = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [products, page, hasMore];
}

class SellerProductDetailsLoaded extends SellerProductsState {
  final SellerProduct product;

  const SellerProductDetailsLoaded({required this.product});

  @override
  List<Object?> get props => [product];
}

class SellerProductActionLoading extends SellerProductsState {
  const SellerProductActionLoading();
}

class SellerProductActionSuccess extends SellerProductsState {
  final String message;
  final SellerProduct? product;

  const SellerProductActionSuccess({required this.message, this.product});

  @override
  List<Object?> get props => [message, product];
}

class SellerProductsFailure extends SellerProductsState {
  final String message;

  const SellerProductsFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class SellerProductsBloc
    extends Bloc<SellerProductsEvent, SellerProductsState> {
  final GetSellerProductsUseCase getProductsUseCase;
  final GetSellerProductUseCase getProductUseCase;
  final CreateSellerProductUseCase createProductUseCase;
  final UpdateSellerProductUseCase updateProductUseCase;
  final DeactivateSellerProductUseCase deactivateProductUseCase;

  SellerProductsBloc({
    required this.getProductsUseCase,
    required this.getProductUseCase,
    required this.createProductUseCase,
    required this.updateProductUseCase,
    required this.deactivateProductUseCase,
  }) : super(const SellerProductsInitial()) {
    on<SellerProductsRequested>(_onProductsRequested);
    on<SellerProductDetailsRequested>(_onProductDetailsRequested);
    on<SellerProductCreated>(_onProductCreated);
    on<SellerProductUpdated>(_onProductUpdated);
    on<SellerProductDeactivated>(_onProductDeactivated);
    on<SellerProductsReset>(_onProductsReset);
  }

  Future<void> _onProductsRequested(
    SellerProductsRequested event,
    Emitter<SellerProductsState> emit,
  ) async {
    emit(const SellerProductsLoading());
    final result = await getProductsUseCase(
      page: event.page,
      pageSize: event.pageSize,
      search: event.search,
      categoryId: event.categoryId,
      isActive: event.isActive,
      lowStock: event.lowStock,
      sort: event.sort,
    );

    result.fold(
      onSuccess: (products) => emit(
        SellerProductsLoaded(
          products: products,
          page: event.page,
          hasMore: products.length >= event.pageSize,
        ),
      ),
      onError: (failure) =>
          emit(SellerProductsFailure(message: failure.message)),
    );
  }

  Future<void> _onProductDetailsRequested(
    SellerProductDetailsRequested event,
    Emitter<SellerProductsState> emit,
  ) async {
    emit(const SellerProductsLoading());
    final result = await getProductUseCase(event.productId);
    result.fold(
      onSuccess: (product) =>
          emit(SellerProductDetailsLoaded(product: product)),
      onError: (failure) =>
          emit(SellerProductsFailure(message: failure.message)),
    );
  }

  Future<void> _onProductCreated(
    SellerProductCreated event,
    Emitter<SellerProductsState> emit,
  ) async {
    emit(const SellerProductActionLoading());
    final result = await createProductUseCase(
      name: event.name,
      description: event.description,
      price: event.price,
      stockQuantity: event.stockQuantity,
      categoryId: event.categoryId,
      sku: event.sku,
      imageUrl: event.imageUrl,
      isActive: event.isActive,
    );

    result.fold(
      onSuccess: (product) => emit(
        SellerProductActionSuccess(
          message: 'Product created successfully!',
          product: product,
        ),
      ),
      onError: (failure) =>
          emit(SellerProductsFailure(message: failure.message)),
    );
  }

  Future<void> _onProductUpdated(
    SellerProductUpdated event,
    Emitter<SellerProductsState> emit,
  ) async {
    emit(const SellerProductActionLoading());
    final result = await updateProductUseCase(
      id: event.productId,
      name: event.name,
      description: event.description,
      price: event.price,
      stockQuantity: event.stockQuantity,
      categoryId: event.categoryId,
      sku: event.sku,
      imageUrl: event.imageUrl,
      isActive: event.isActive,
    );

    result.fold(
      onSuccess: (product) => emit(
        SellerProductActionSuccess(
          message: 'Product updated successfully!',
          product: product,
        ),
      ),
      onError: (failure) =>
          emit(SellerProductsFailure(message: failure.message)),
    );
  }

  Future<void> _onProductDeactivated(
    SellerProductDeactivated event,
    Emitter<SellerProductsState> emit,
  ) async {
    emit(const SellerProductActionLoading());
    final result = await deactivateProductUseCase(event.productId);
    result.fold(
      onSuccess: (_) => emit(
        const SellerProductActionSuccess(
          message: 'Product deactivated successfully.',
        ),
      ),
      onError: (failure) =>
          emit(SellerProductsFailure(message: failure.message)),
    );
  }

  void _onProductsReset(
    SellerProductsReset event,
    Emitter<SellerProductsState> emit,
  ) {
    emit(const SellerProductsInitial());
  }
}
