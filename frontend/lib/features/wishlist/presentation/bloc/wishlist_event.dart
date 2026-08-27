import 'package:equatable/equatable.dart';

sealed class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

final class WishlistRequested extends WishlistEvent {
  const WishlistRequested();
}

final class WishlistRefreshed extends WishlistEvent {
  const WishlistRefreshed();
}

final class AddToWishlist extends WishlistEvent {
  const AddToWishlist(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

final class RemoveFromWishlist extends WishlistEvent {
  const RemoveFromWishlist(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

final class ToggleWishlist extends WishlistEvent {
  const ToggleWishlist(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

final class ClearWishlist extends WishlistEvent {
  const ClearWishlist();
}

final class WishlistReset extends WishlistEvent {
  const WishlistReset();
}
