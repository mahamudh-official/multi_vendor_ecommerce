import 'package:equatable/equatable.dart';

import '../../domain/entities/wishlist_item.dart';

sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

final class WishlistInitial extends WishlistState {
  const WishlistInitial();
}

final class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

final class WishlistLoaded extends WishlistState {
  const WishlistLoaded({required this.items, this.message});

  final List<WishlistItem> items;
  final String? message;

  Set<String> get productIds => items.map((i) => i.product.id).toSet();
  bool containsProduct(String productId) => productIds.contains(productId);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get itemCount => items.length;

  WishlistLoaded copyWith({List<WishlistItem>? items, String? message}) {
    return WishlistLoaded(items: items ?? this.items, message: message);
  }

  @override
  List<Object?> get props => [items, message];
}

final class WishlistFailure extends WishlistState {
  const WishlistFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
