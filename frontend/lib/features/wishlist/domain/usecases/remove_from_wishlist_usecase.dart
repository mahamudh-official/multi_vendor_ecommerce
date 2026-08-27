import '../../../../core/error/result.dart';
import '../repositories/wishlist_repository.dart';

class RemoveFromWishlistUseCase {
  const RemoveFromWishlistUseCase(this._repository);

  final WishlistRepository _repository;

  Future<Result<void>> call(String productId) =>
      _repository.removeFromWishlist(productId);
}
