import 'package:equatable/equatable.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

final class CartLoaded extends CartState {
  const CartLoaded({
    required this.cart,
    this.updatingItemIds = const {},
    this.message,
  });

  final Cart cart;
  final Set<String> updatingItemIds;
  final String? message;

  List<CartItem> get items => cart.items;
  int get itemCount => cart.itemCount;
  double get subtotal => cart.subtotal;
  bool get isEmpty => cart.isEmpty;

  CartLoaded copyWith({
    Cart? cart,
    Set<String>? updatingItemIds,
    String? message,
  }) {
    return CartLoaded(
      cart: cart ?? this.cart,
      updatingItemIds: updatingItemIds ?? this.updatingItemIds,
      message: message,
    );
  }

  @override
  List<Object?> get props => [cart, updatingItemIds, message];
}

final class CartFailure extends CartState {
  const CartFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
