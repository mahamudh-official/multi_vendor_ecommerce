import '../../../../core/error/result.dart';
import '../entities/cart.dart';

abstract interface class CartRepository {
  Future<Result<Cart>> getCart();

  Future<Result<Cart>> addToCart({
    required String productId,
    required int quantity,
  });

  Future<Result<Cart>> updateCartItemQuantity({
    required String itemId,
    required int quantity,
  });

  Future<Result<Cart>> removeCartItem({required String itemId});

  Future<Result<Cart>> clearCart();
}
