import '../../../../core/network/dio_client.dart';
import '../models/wishlist_item_model.dart';

abstract interface class WishlistRemoteDataSource {
  Future<List<WishlistItemModel>> getWishlist();

  Future<WishlistItemModel> addToWishlist(String productId);

  Future<void> removeFromWishlist(String productId);

  Future<void> clearWishlist();
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  const WishlistRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<List<WishlistItemModel>> getWishlist() async {
    final response = await dioClient.get<List<dynamic>>('/wishlist');
    final data = response.data ?? [];
    return data
        .map((json) => WishlistItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WishlistItemModel> addToWishlist(String productId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      '/wishlist/items/$productId',
    );
    return WishlistItemModel.fromJson(response.data!);
  }

  @override
  Future<void> removeFromWishlist(String productId) async {
    await dioClient.delete<dynamic>('/wishlist/items/$productId');
  }

  @override
  Future<void> clearWishlist() async {
    await dioClient.delete<dynamic>('/wishlist');
  }
}
