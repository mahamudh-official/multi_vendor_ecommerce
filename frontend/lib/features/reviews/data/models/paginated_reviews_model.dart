import '../../domain/entities/paginated_reviews.dart';
import 'rating_distribution_model.dart';
import 'review_model.dart';

class PaginatedReviewsModel {
  const PaginatedReviewsModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    this.hasNext = false,
    this.hasPrevious = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.ratingDistribution = const RatingDistributionModel(),
  });

  factory PaginatedReviewsModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final rawRating = json['average_rating'];
    final double averageRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '0.0') ?? 0.0;

    final int reviewCount = json['review_count'] is int
        ? json['review_count'] as int
        : int.tryParse(json['review_count']?.toString() ?? '0') ?? 0;

    return PaginatedReviewsModel(
      items: rawItems
          .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
      averageRating: averageRating,
      reviewCount: reviewCount,
      ratingDistribution: json['rating_distribution'] != null
          ? RatingDistributionModel.fromJson(
              json['rating_distribution'] as Map<String, dynamic>,
            )
          : const RatingDistributionModel(),
    );
  }

  final List<ReviewModel> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final double averageRating;
  final int reviewCount;
  final RatingDistributionModel ratingDistribution;

  PaginatedReviews toEntity() {
    return PaginatedReviews(
      items: items.map((m) => m.toEntity()).toList(),
      page: page,
      pageSize: pageSize,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
      averageRating: averageRating,
      reviewCount: reviewCount,
      ratingDistribution: ratingDistribution.toEntity(),
    );
  }
}
