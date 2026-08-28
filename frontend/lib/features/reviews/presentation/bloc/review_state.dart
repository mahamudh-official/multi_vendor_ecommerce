import 'package:equatable/equatable.dart';

import '../../domain/entities/rating_distribution.dart';
import '../../domain/entities/review.dart';

enum ReviewStatus { initial, loading, loaded, loadingMore, error }

enum ReviewActionStatus { initial, submitting, success, error }

class ReviewState extends Equatable {
  const ReviewState({
    this.status = ReviewStatus.initial,
    this.actionStatus = ReviewActionStatus.initial,
    this.productId = '',
    this.reviews = const [],
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.ratingDistribution = const RatingDistribution(),
    this.ratingFilter,
    this.verifiedOnlyFilter,
    this.errorMessage,
    this.actionErrorMessage,
  });

  final ReviewStatus status;
  final ReviewActionStatus actionStatus;
  final String productId;
  final List<Review> reviews;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final double averageRating;
  final int reviewCount;
  final RatingDistribution ratingDistribution;
  final int? ratingFilter;
  final bool? verifiedOnlyFilter;
  final String? errorMessage;
  final String? actionErrorMessage;

  bool get isLoading => status == ReviewStatus.loading;
  bool get isLoadingMore => status == ReviewStatus.loadingMore;
  bool get isSubmitting => actionStatus == ReviewActionStatus.submitting;

  ReviewState copyWith({
    ReviewStatus? status,
    ReviewActionStatus? actionStatus,
    String? productId,
    List<Review>? reviews,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
    double? averageRating,
    int? reviewCount,
    RatingDistribution? ratingDistribution,
    int? ratingFilter,
    bool? verifiedOnlyFilter,
    String? errorMessage,
    String? actionErrorMessage,
  }) {
    return ReviewState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      productId: productId ?? this.productId,
      reviews: reviews ?? this.reviews,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      ratingFilter: ratingFilter ?? this.ratingFilter,
      verifiedOnlyFilter: verifiedOnlyFilter ?? this.verifiedOnlyFilter,
      errorMessage: errorMessage,
      actionErrorMessage: actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    actionStatus,
    productId,
    reviews,
    page,
    pageSize,
    total,
    totalPages,
    hasNext,
    hasPrevious,
    averageRating,
    reviewCount,
    ratingDistribution,
    ratingFilter,
    verifiedOnlyFilter,
    errorMessage,
    actionErrorMessage,
  ];
}
