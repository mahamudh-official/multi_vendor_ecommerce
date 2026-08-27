import 'package:equatable/equatable.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

final class CartRequested extends CartEvent {
  const CartRequested();
}

final class CartRefreshed extends CartEvent {
  const CartRefreshed();
}

final class AddToCart extends CartEvent {
  const AddToCart({required this.productId, this.quantity = 1});

  final String productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

final class CartItemQuantityIncreased extends CartEvent {
  const CartItemQuantityIncreased(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class CartItemQuantityDecreased extends CartEvent {
  const CartItemQuantityDecreased(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class CartItemQuantityChanged extends CartEvent {
  const CartItemQuantityChanged({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  @override
  List<Object?> get props => [itemId, quantity];
}

final class RemoveCartItem extends CartEvent {
  const RemoveCartItem(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class ClearCart extends CartEvent {
  const ClearCart();
}

final class CartReset extends CartEvent {
  const CartReset();
}
