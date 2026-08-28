import '../../../../core/network/dio_client.dart';
import '../models/paginated_reviews_model.dart';
import '../models/review_model.dart';

abstract interface class ReviewRemoteDataSource {
  Future<PaginatedReviewsModel> getProductReviews({
    required String productId,
    int page = 1,
    int pageSize = 10,
    int? rating,
    bool? verifiedOnly,
  });

  Future<ReviewModel> createReview({
    required String productId,
    required int rating,
    String? title,
    String? comment,
  });

  Future<ReviewModel> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
  });

  Future<void> deleteReview(String reviewId);

  Future<PaginatedReviewsModel> getMyReviews({int page = 1, int pageSize = 10});
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  const ReviewRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<PaginatedReviewsModel> getProductReviews({
    required String productId,
    int page = 1,
    int pageSize = 10,
    int? rating,
    bool? verifiedOnly,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (rating != null) queryParams['rating'] = rating;
    if (verifiedOnly != null) queryParams['verified_only'] = verifiedOnly;

    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/products/$productId/reviews',
      queryParameters: queryParams,
    );

    return PaginatedReviewsModel.fromJson(response.data!);
  }

  @override
  Future<ReviewModel> createReview({
    required String productId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/api/v1/products/$productId/reviews',
      data: {
        'rating': rating,
        if (title != null && title.isNotEmpty) 'title': title,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );

    return ReviewModel.fromJson(response.data!);
  }

  @override
  Future<ReviewModel> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
  }) async {
    final data = <String, dynamic>{};
    if (rating != null) data['rating'] = rating;
    if (title != null) data['title'] = title;
    if (comment != null) data['comment'] = comment;

    final response = await _dioClient.patch<Map<String, dynamic>>(
      '/api/v1/reviews/$reviewId',
      data: data,
    );

    return ReviewModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _dioClient.delete<dynamic>('/api/v1/reviews/$reviewId');
  }

  @override
  Future<PaginatedReviewsModel> getMyReviews({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/reviews/me',
      queryParameters: {'page': page, 'page_size': pageSize},
    );

    return PaginatedReviewsModel.fromJson(response.data!);
  }
}
