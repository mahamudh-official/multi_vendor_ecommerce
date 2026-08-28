import '../../../../core/error/result.dart';
import '../entities/paginated_reviews.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetProductReviewsUseCase {
  const GetProductReviewsUseCase(this._repository);
  final ReviewRepository _repository;

  Future<Result<PaginatedReviews>> call({
    required String productId,
    int page = 1,
    int pageSize = 10,
    int? rating,
    bool? verifiedOnly,
  }) {
    return _repository.getProductReviews(
      productId: productId,
      page: page,
      pageSize: pageSize,
      rating: rating,
      verifiedOnly: verifiedOnly,
    );
  }
}

class CreateReviewUseCase {
  const CreateReviewUseCase(this._repository);
  final ReviewRepository _repository;

  Future<Result<Review>> call({
    required String productId,
    required int rating,
    String? title,
    String? comment,
  }) {
    return _repository.createReview(
      productId: productId,
      rating: rating,
      title: title,
      comment: comment,
    );
  }
}

class UpdateReviewUseCase {
  const UpdateReviewUseCase(this._repository);
  final ReviewRepository _repository;

  Future<Result<Review>> call({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
  }) {
    return _repository.updateReview(
      reviewId: reviewId,
      rating: rating,
      title: title,
      comment: comment,
    );
  }
}

class DeleteReviewUseCase {
  const DeleteReviewUseCase(this._repository);
  final ReviewRepository _repository;

  Future<Result<void>> call(String reviewId) {
    return _repository.deleteReview(reviewId);
  }
}

class GetMyReviewsUseCase {
  const GetMyReviewsUseCase(this._repository);
  final ReviewRepository _repository;

  Future<Result<PaginatedReviews>> call({int page = 1, int pageSize = 10}) {
    return _repository.getMyReviews(page: page, pageSize: pageSize);
  }
}
