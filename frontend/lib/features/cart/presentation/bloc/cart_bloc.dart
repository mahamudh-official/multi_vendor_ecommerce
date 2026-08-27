import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/remove_cart_item_usecase.dart';
import '../../domain/usecases/update_cart_item_usecase.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// BLoC managing shopping cart state, additions, quantity updates, and calculations.
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required this.getCartUseCase,
    required this.addToCartUseCase,
    required this.updateCartItemUseCase,
    required this.removeCartItemUseCase,
    required this.clearCartUseCase,
  }) : super(const CartInitial()) {
    on<CartRequested>(_onCartRequested);
    on<CartRefreshed>(_onCartRefreshed);
    on<AddToCart>(_onAddToCart);
    on<CartItemQuantityIncreased>(_onQuantityIncreased);
    on<CartItemQuantityDecreased>(_onQuantityDecreased);
    on<CartItemQuantityChanged>(_onQuantityChanged);
    on<RemoveCartItem>(_onRemoveCartItem);
    on<ClearCart>(_onClearCart);
    on<CartReset>(_onCartReset);
  }

  final GetCartUseCase getCartUseCase;
  final AddToCartUseCase addToCartUseCase;
  final UpdateCartItemUseCase updateCartItemUseCase;
  final RemoveCartItemUseCase removeCartItemUseCase;
  final ClearCartUseCase clearCartUseCase;

  Future<void> _onCartRequested(
    CartRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    final result = await getCartUseCase();
    result.fold(
      onSuccess: (cart) => emit(CartLoaded(cart: cart)),
      onError: (failure) => emit(CartFailure(failure.message)),
    );
  }

  Future<void> _onCartRefreshed(
    CartRefreshed event,
    Emitter<CartState> emit,
  ) async {
    final result = await getCartUseCase();
    result.fold(
      onSuccess: (cart) => emit(CartLoaded(cart: cart)),
      onError: (failure) => emit(CartFailure(failure.message)),
    );
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    final result = await addToCartUseCase(
      productId: event.productId,
      quantity: event.quantity,
    );
    result.fold(
      onSuccess: (cart) =>
          emit(CartLoaded(cart: cart, message: 'Item added to cart!')),
      onError: (failure) {
        if (state is CartLoaded) {
          emit((state as CartLoaded).copyWith(message: failure.message));
        } else {
          emit(CartFailure(failure.message));
        }
      },
    );
  }

  Future<void> _onQuantityIncreased(
    CartItemQuantityIncreased event,
    Emitter<CartState> emit,
  ) async {
    if (state is! CartLoaded) return;
    final current = state as CartLoaded;
    final item = current.items.firstWhere(
      (i) => i.id == event.itemId,
      orElse: () => current.items.first,
    );

    emit(
      current.copyWith(
        updatingItemIds: {...current.updatingItemIds, event.itemId},
      ),
    );

    final result = await updateCartItemUseCase(
      itemId: event.itemId,
      quantity: item.quantity + 1,
    );

    result.fold(
      onSuccess: (cart) => emit(CartLoaded(cart: cart)),
      onError: (failure) => emit(
        current.copyWith(
          updatingItemIds: current.updatingItemIds
              .where((id) => id != event.itemId)
              .toSet(),
          message: failure.message,
        ),
      ),
    );
  }

  Future<void> _onQuantityDecreased(
    CartItemQuantityDecreased event,
    Emitter<CartState> emit,
  ) async {
    if (state is! CartLoaded) return;
    final current = state as CartLoaded;
    final item = current.items.firstWhere(
      (i) => i.id == event.itemId,
      orElse: () => current.items.first,
    );

    if (item.quantity <= 1) {
      add(RemoveCartItem(event.itemId));
      return;
    }

    emit(
      current.copyWith(
        updatingItemIds: {...current.updatingItemIds, event.itemId},
      ),
    );

    final result = await updateCartItemUseCase(
      itemId: event.itemId,
      quantity: item.quantity - 1,
    );

    result.fold(
      onSuccess: (cart) => emit(CartLoaded(cart: cart)),
      onError: (failure) => emit(
        current.copyWith(
          updatingItemIds: current.updatingItemIds
              .where((id) => id != event.itemId)
              .toSet(),
          message: failure.message,
        ),
      ),
    );
  }

  Future<void> _onQuantityChanged(
    CartItemQuantityChanged event,
    Emitter<CartState> emit,
  ) async {
    if (state is! CartLoaded) return;
    final current = state as CartLoaded;

    if (event.quantity <= 0) {
      add(RemoveCartItem(event.itemId));
      return;
    }

    emit(
      current.copyWith(
        updatingItemIds: {...current.updatingItemIds, event.itemId},
      ),
    );

    final result = await updateCartItemUseCase(
      itemId: event.itemId,
      quantity: event.quantity,
    );

    result.fold(
      onSuccess: (cart) => emit(CartLoaded(cart: cart)),
      onError: (failure) => emit(
        current.copyWith(
          updatingItemIds: current.updatingItemIds
              .where((id) => id != event.itemId)
              .toSet(),
          message: failure.message,
        ),
      ),
    );
  }

  Future<void> _onRemoveCartItem(
    RemoveCartItem event,
    Emitter<CartState> emit,
  ) async {
    if (state is! CartLoaded) return;
    final current = state as CartLoaded;

    emit(
      current.copyWith(
        updatingItemIds: {...current.updatingItemIds, event.itemId},
      ),
    );

    final result = await removeCartItemUseCase(itemId: event.itemId);
    result.fold(
      onSuccess: (cart) =>
          emit(CartLoaded(cart: cart, message: 'Item removed.')),
      onError: (failure) => emit(
        current.copyWith(
          updatingItemIds: current.updatingItemIds
              .where((id) => id != event.itemId)
              .toSet(),
          message: failure.message,
        ),
      ),
    );
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    emit(const CartLoading());
    final result = await clearCartUseCase();
    result.fold(
      onSuccess: (cart) =>
          emit(CartLoaded(cart: cart, message: 'Cart cleared.')),
      onError: (failure) => emit(CartFailure(failure.message)),
    );
  }

  void _onCartReset(CartReset event, Emitter<CartState> emit) {
    emit(const CartInitial());
  }
}
