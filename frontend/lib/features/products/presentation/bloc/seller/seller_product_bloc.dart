import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/create_product_usecase.dart';
import '../../../domain/usecases/delete_product_usecase.dart';
import '../../../domain/usecases/get_products_usecase.dart';
import '../../../domain/usecases/update_product_usecase.dart';
import 'seller_product_event.dart';
import 'seller_product_state.dart';

/// BLoC for seller's own product inventory management.
class SellerProductBloc extends Bloc<SellerProductEvent, SellerProductState> {
  SellerProductBloc({
    required this.getProductsUseCase,
    required this.createProductUseCase,
    required this.updateProductUseCase,
    required this.deleteProductUseCase,
  }) : super(const SellerProductInitial()) {
    on<SellerProductsRequested>(_onSellerProductsRequested);
    on<SellerProductCreateSubmitted>(_onSellerProductCreateSubmitted);
    on<SellerProductUpdateSubmitted>(_onSellerProductUpdateSubmitted);
    on<SellerProductDeleteSubmitted>(_onSellerProductDeleteSubmitted);
  }

  final GetProductsUseCase getProductsUseCase;
  final CreateProductUseCase createProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final DeleteProductUseCase deleteProductUseCase;

  Future<void> _onSellerProductsRequested(
    SellerProductsRequested event,
    Emitter<SellerProductState> emit,
  ) async {
    emit(const SellerProductLoading());
    final result = await getProductsUseCase(
      page: 1,
      pageSize: 50,
      sellerId: event.sellerId,
    );
    result.fold(
      onSuccess: (data) => emit(SellerProductsLoaded(data.items)),
      onError: (failure) => emit(SellerProductFailure(failure.message)),
    );
  }

  Future<void> _onSellerProductCreateSubmitted(
    SellerProductCreateSubmitted event,
    Emitter<SellerProductState> emit,
  ) async {
    emit(const SellerProductLoading());
    final result = await createProductUseCase(
      name: event.name,
      description: event.description,
      price: event.price,
      compareAtPrice: event.compareAtPrice,
      stockQuantity: event.stockQuantity,
      sku: event.sku,
      categoryId: event.categoryId,
      imageUrl: event.imageUrl,
      images: event.images,
      isFeatured: event.isFeatured,
    );

    await result.fold(
      onSuccess: (_) async {
        emit(const SellerProductActionSuccess('Product created successfully!'));
        add(SellerProductsRequested(event.sellerId));
      },
      onError: (failure) async => emit(SellerProductFailure(failure.message)),
    );
  }

  Future<void> _onSellerProductUpdateSubmitted(
    SellerProductUpdateSubmitted event,
    Emitter<SellerProductState> emit,
  ) async {
    emit(const SellerProductLoading());
    final result = await updateProductUseCase(
      id: event.id,
      name: event.name,
      description: event.description,
      price: event.price,
      compareAtPrice: event.compareAtPrice,
      stockQuantity: event.stockQuantity,
      sku: event.sku,
      categoryId: event.categoryId,
      imageUrl: event.imageUrl,
      images: event.images,
      isFeatured: event.isFeatured,
      isActive: event.isActive,
    );

    await result.fold(
      onSuccess: (_) async {
        emit(const SellerProductActionSuccess('Product updated successfully!'));
        add(SellerProductsRequested(event.sellerId));
      },
      onError: (failure) async => emit(SellerProductFailure(failure.message)),
    );
  }

  Future<void> _onSellerProductDeleteSubmitted(
    SellerProductDeleteSubmitted event,
    Emitter<SellerProductState> emit,
  ) async {
    emit(const SellerProductLoading());
    final result = await deleteProductUseCase(event.productId);

    await result.fold(
      onSuccess: (_) async {
        emit(
          const SellerProductActionSuccess('Product deactivated successfully!'),
        );
        add(SellerProductsRequested(event.sellerId));
      },
      onError: (failure) async => emit(SellerProductFailure(failure.message)),
    );
  }
}
