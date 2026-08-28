import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/paginated_reviews.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl(this._remoteDataSource);

  final ReviewRemoteDataSource _remoteDataSource;

  @override
  Future<Result<PaginatedReviews>> getProductReviews({
    required String productId,
    int page = 1,
    int pageSize = 10,
    int? rating,
    bool? verifiedOnly,
  }) async {
    try {
      final model = await _remoteDataSource.getProductReviews(
        productId: productId,
        page: page,
        pageSize: pageSize,
        rating: rating,
        verifiedOnly: verifiedOnly,
      );
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Review>> createReview({
    required String productId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final model = await _remoteDataSource.createReview(
        productId: productId,
        rating: rating,
        title: title,
        comment: comment,
      );
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Review>> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
  }) async {
    try {
      final model = await _remoteDataSource.updateReview(
        reviewId: reviewId,
        rating: rating,
        title: title,
        comment: comment,
      );
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteReview(String reviewId) async {
    try {
      await _remoteDataSource.deleteReview(reviewId);
      return const Success(null);
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<PaginatedReviews>> getMyReviews({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final model = await _remoteDataSource.getMyReviews(
        page: page,
        pageSize: pageSize,
      );
      return Success(model.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
