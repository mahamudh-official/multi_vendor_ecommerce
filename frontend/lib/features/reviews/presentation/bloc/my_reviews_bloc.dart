import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/review.dart';
import '../../domain/usecases/review_usecases.dart';

// Events
sealed class MyReviewsEvent extends Equatable {
  const MyReviewsEvent();
  @override
  List<Object?> get props => [];
}

final class FetchMyReviews extends MyReviewsEvent {
  const FetchMyReviews({this.page = 1});
  final int page;
  @override
  List<Object?> get props => [page];
}

final class DeleteMyReview extends MyReviewsEvent {
  const DeleteMyReview(this.reviewId);
  final String reviewId;
  @override
  List<Object?> get props => [reviewId];
}

// States
enum MyReviewsStatus { initial, loading, loaded, error }

class MyReviewsState extends Equatable {
  const MyReviewsState({
    this.status = MyReviewsStatus.initial,
    this.reviews = const [],
    this.page = 1,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.errorMessage,
  });

  final MyReviewsStatus status;
  final List<Review> reviews;
  final int page;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final String? errorMessage;

  bool get isLoading => status == MyReviewsStatus.loading;

  MyReviewsState copyWith({
    MyReviewsStatus? status,
    List<Review>? reviews,
    int? page,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
    String? errorMessage,
  }) {
    return MyReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    reviews,
    page,
    total,
    totalPages,
    hasNext,
    hasPrevious,
    errorMessage,
  ];
}

// BLoC
class MyReviewsBloc extends Bloc<MyReviewsEvent, MyReviewsState> {
  MyReviewsBloc({
    required this.getMyReviewsUseCase,
    required this.deleteReviewUseCase,
  }) : super(const MyReviewsState()) {
    on<FetchMyReviews>(_onFetchMyReviews);
    on<DeleteMyReview>(_onDeleteMyReview);
  }

  final GetMyReviewsUseCase getMyReviewsUseCase;
  final DeleteReviewUseCase deleteReviewUseCase;

  Future<void> _onFetchMyReviews(
    FetchMyReviews event,
    Emitter<MyReviewsState> emit,
  ) async {
    emit(state.copyWith(status: MyReviewsStatus.loading));

    final result = await getMyReviewsUseCase(page: event.page);

    result.fold(
      onSuccess: (paginated) {
        emit(
          state.copyWith(
            status: MyReviewsStatus.loaded,
            reviews: paginated.items,
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
            status: MyReviewsStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteMyReview(
    DeleteMyReview event,
    Emitter<MyReviewsState> emit,
  ) async {
    final result = await deleteReviewUseCase(event.reviewId);
    result.fold(
      onSuccess: (_) {
        add(FetchMyReviews(page: state.page));
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: MyReviewsStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }
}
