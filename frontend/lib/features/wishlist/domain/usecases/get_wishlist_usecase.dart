import '../../../../core/error/result.dart';
import '../entities/wishlist_item.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlistUseCase {
  const GetWishlistUseCase(this._repository);

  final WishlistRepository _repository;

  Future<Result<List<WishlistItem>>> call() => _repository.getWishlist();
}
