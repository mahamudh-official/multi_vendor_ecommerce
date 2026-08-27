import '../../../../core/network/dio_client.dart';
import '../models/cart_model.dart';

abstract interface class CartRemoteDataSource {
  Future<CartModel> getCart();

  Future<CartModel> addToCart({
    required String productId,
    required int quantity,
  });

  Future<CartModel> updateCartItemQuantity({
    required String itemId,
    required int quantity,
  });

  Future<CartModel> removeCartItem({required String itemId});

  Future<CartModel> clearCart();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  const CartRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<CartModel> getCart() async {
    final response = await dioClient.get<Map<String, dynamic>>('/cart');
    return CartModel.fromJson(response.data!);
  }

  @override
  Future<CartModel> addToCart({
    required String productId,
    required int quantity,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      '/cart/items',
      data: {'product_id': productId, 'quantity': quantity},
    );
    return CartModel.fromJson(response.data!);
  }

  @override
  Future<CartModel> updateCartItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final response = await dioClient.patch<Map<String, dynamic>>(
      '/cart/items/$itemId',
      data: {'quantity': quantity},
    );
    return CartModel.fromJson(response.data!);
  }

  @override
  Future<CartModel> removeCartItem({required String itemId}) async {
    final response = await dioClient.delete<Map<String, dynamic>>(
      '/cart/items/$itemId',
    );
    return CartModel.fromJson(response.data!);
  }

  @override
  Future<CartModel> clearCart() async {
    final response = await dioClient.delete<Map<String, dynamic>>('/cart');
    return CartModel.fromJson(response.data!);
  }
}
