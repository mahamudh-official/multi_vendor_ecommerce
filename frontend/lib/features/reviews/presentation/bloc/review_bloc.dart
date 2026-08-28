import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/review_usecases.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  ReviewBloc({
    required this.getProductReviewsUseCase,
    required this.createReviewUseCase,
    required this.updateReviewUseCase,
    required this.deleteReviewUseCase,
  }) : super(const ReviewState()) {
    on<LoadProductReviews>(_onLoadProductReviews);
    on<LoadMoreProductReviews>(_onLoadMoreProductReviews);
    on<SubmitReview>(_onSubmitReview);
    on<EditReview>(_onEditReview);
    on<RemoveReview>(_onRemoveReview);
  }

  final GetProductReviewsUseCase getProductReviewsUseCase;
  final CreateReviewUseCase createReviewUseCase;
  final UpdateReviewUseCase updateReviewUseCase;
  final DeleteReviewUseCase deleteReviewUseCase;

  Future<void> _onLoadProductReviews(
    LoadProductReviews event,
    Emitter<ReviewState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ReviewStatus.loading,
        productId: event.productId,
        page: event.page,
        ratingFilter: event.rating,
        verifiedOnlyFilter: event.verifiedOnly,
      ),
    );

    final result = await getProductReviewsUseCase(
      productId: event.productId,
      page: event.page,
      pageSize: state.pageSize,
      rating: event.rating,
      verifiedOnly: event.verifiedOnly,
    );

    result.fold(
      onSuccess: (paginated) {
        emit(
          state.copyWith(
            status: ReviewStatus.loaded,
            reviews: paginated.items,
            page: paginated.page,
            total: paginated.total,
            totalPages: paginated.totalPages,
            hasNext: paginated.hasNext,
            hasPrevious: paginated.hasPrevious,
            averageRating: paginated.averageRating,
            reviewCount: paginated.reviewCount,
            ratingDistribution: paginated.ratingDistribution,
          ),
        );
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: ReviewStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreProductReviews(
    LoadMoreProductReviews event,
    Emitter<ReviewState> emit,
  ) async {
    if (!state.hasNext || state.isLoadingMore || state.isLoading) return;

    final nextPage = state.page + 1;
    emit(state.copyWith(status: ReviewStatus.loadingMore));

    final result = await getProductReviewsUseCase(
      productId: state.productId,
      page: nextPage,
      pageSize: state.pageSize,
      rating: state.ratingFilter,
      verifiedOnly: state.verifiedOnlyFilter,
    );

    result.fold(
      onSuccess: (paginated) {
        emit(
          state.copyWith(
            status: ReviewStatus.loaded,
            reviews: [...state.reviews, ...paginated.items],
            page: paginated.page,
            total: paginated.total,
            totalPages: paginated.totalPages,
            hasNext: paginated.hasNext,
            hasPrevious: paginated.hasPrevious,
          ),
        );
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: ReviewStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> _onSubmitReview(
    SubmitReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ReviewActionStatus.submitting));

    final result = await createReviewUseCase(
      productId: event.productId,
      rating: event.rating,
      title: event.title,
      comment: event.comment,
    );

    result.fold(
      onSuccess: (review) {
        emit(state.copyWith(actionStatus: ReviewActionStatus.success));
        // Refresh reviews
        add(LoadProductReviews(productId: event.productId));
      },
      onError: (failure) {
        emit(
          state.copyWith(
            actionStatus: ReviewActionStatus.error,
            actionErrorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> _onEditReview(
    EditReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ReviewActionStatus.submitting));

    final result = await updateReviewUseCase(
      reviewId: event.reviewId,
      rating: event.rating,
      title: event.title,
      comment: event.comment,
    );

    result.fold(
      onSuccess: (review) {
        emit(state.copyWith(actionStatus: ReviewActionStatus.success));
        add(LoadProductReviews(productId: event.productId));
      },
      onError: (failure) {
        emit(
          state.copyWith(
            actionStatus: ReviewActionStatus.error,
            actionErrorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> _onRemoveReview(
    RemoveReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ReviewActionStatus.submitting));

    final result = await deleteReviewUseCase(event.reviewId);

    result.fold(
      onSuccess: (_) {
        emit(state.copyWith(actionStatus: ReviewActionStatus.success));
        add(LoadProductReviews(productId: event.productId));
      },
      onError: (failure) {
        emit(
          state.copyWith(
            actionStatus: ReviewActionStatus.error,
            actionErrorMessage: failure.message,
          ),
        );
      },
    );
  }
}
