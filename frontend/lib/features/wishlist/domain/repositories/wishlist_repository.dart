import '../../../../core/error/result.dart';
import '../entities/wishlist_item.dart';

abstract interface class WishlistRepository {
  Future<Result<List<WishlistItem>>> getWishlist();

  Future<Result<WishlistItem>> addToWishlist(String productId);

  Future<Result<void>> removeFromWishlist(String productId);

  Future<Result<void>> clearWishlist();
}
