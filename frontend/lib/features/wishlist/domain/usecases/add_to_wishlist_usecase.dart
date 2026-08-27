import '../../../../core/error/result.dart';
import '../entities/wishlist_item.dart';
import '../repositories/wishlist_repository.dart';

class AddToWishlistUseCase {
  const AddToWishlistUseCase(this._repository);

  final WishlistRepository _repository;

  Future<Result<WishlistItem>> call(String productId) =>
      _repository.addToWishlist(productId);
}
