import '../../../../core/error/result.dart';
import '../entities/paginated_reviews.dart';
import '../entities/review.dart';

abstract interface class ReviewRepository {
  Future<Result<PaginatedReviews>> getProductReviews({
    required String productId,
    int page = 1,
    int pageSize = 10,
    int? rating,
    bool? verifiedOnly,
  });

  Future<Result<Review>> createReview({
    required String productId,
    required int rating,
    String? title,
    String? comment,
  });

  Future<Result<Review>> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
  });

  Future<Result<void>> deleteReview(String reviewId);

  Future<Result<PaginatedReviews>> getMyReviews({
    int page = 1,
    int pageSize = 10,
  });
}
