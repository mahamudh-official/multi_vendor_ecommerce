import '../../../../core/error/result.dart';
import '../repositories/wishlist_repository.dart';

class ClearWishlistUseCase {
  const ClearWishlistUseCase(this._repository);

  final WishlistRepository _repository;

  Future<Result<void>> call() => _repository.clearWishlist();
}
