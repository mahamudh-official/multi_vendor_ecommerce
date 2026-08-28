import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/reviews/domain/entities/paginated_reviews.dart';
import 'package:multi_vendor_ecommerce/features/reviews/domain/entities/rating_distribution.dart';
import 'package:multi_vendor_ecommerce/features/reviews/domain/entities/review.dart';
import 'package:multi_vendor_ecommerce/features/reviews/domain/usecases/review_usecases.dart';
import 'package:multi_vendor_ecommerce/features/reviews/presentation/bloc/review_bloc.dart';
import 'package:multi_vendor_ecommerce/features/reviews/presentation/bloc/review_event.dart';
import 'package:multi_vendor_ecommerce/features/reviews/presentation/bloc/review_state.dart';

class MockGetProductReviewsUseCase extends Mock
    implements GetProductReviewsUseCase {}

class MockCreateReviewUseCase extends Mock implements CreateReviewUseCase {}

class MockUpdateReviewUseCase extends Mock implements UpdateReviewUseCase {}

class MockDeleteReviewUseCase extends Mock implements DeleteReviewUseCase {}

void main() {
  late MockGetProductReviewsUseCase mockGetProductReviewsUseCase;
  late MockCreateReviewUseCase mockCreateReviewUseCase;
  late MockUpdateReviewUseCase mockUpdateReviewUseCase;
  late MockDeleteReviewUseCase mockDeleteReviewUseCase;
  late ReviewBloc reviewBloc;

  final sampleReview = Review(
    id: 'rev-1',
    productId: 'prod-123',
    user: const ReviewUserSummary(id: 'user-1', fullName: 'Alice Walker'),
    orderItemId: 'item-1',
    rating: 5,
    title: 'Outstanding quality!',
    comment: 'Exceeded all expectations.',
    isVerifiedPurchase: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final samplePaginated = PaginatedReviews(
    items: [sampleReview],
    page: 1,
    pageSize: 10,
    total: 1,
    totalPages: 1,
    averageRating: 5.0,
    reviewCount: 1,
    ratingDistribution: const RatingDistribution(fiveStar: 1),
  );

  setUp(() {
    mockGetProductReviewsUseCase = MockGetProductReviewsUseCase();
    mockCreateReviewUseCase = MockCreateReviewUseCase();
    mockUpdateReviewUseCase = MockUpdateReviewUseCase();
    mockDeleteReviewUseCase = MockDeleteReviewUseCase();

    reviewBloc = ReviewBloc(
      getProductReviewsUseCase: mockGetProductReviewsUseCase,
      createReviewUseCase: mockCreateReviewUseCase,
      updateReviewUseCase: mockUpdateReviewUseCase,
      deleteReviewUseCase: mockDeleteReviewUseCase,
    );
  });

  tearDown(() {
    reviewBloc.close();
  });

  group('ReviewBloc', () {
    test('initial state has ReviewStatus.initial', () {
      expect(reviewBloc.state.status, ReviewStatus.initial);
      expect(reviewBloc.state.reviews, isEmpty);
    });

    blocTest<ReviewBloc, ReviewState>(
      'emits [loading, loaded] when LoadProductReviews is added',
      build: () {
        when(
          () => mockGetProductReviewsUseCase(
            productId: any(named: 'productId'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            rating: any(named: 'rating'),
            verifiedOnly: any(named: 'verifiedOnly'),
          ),
        ).thenAnswer((_) async => Success(samplePaginated));
        return reviewBloc;
      },
      act: (bloc) => bloc.add(const LoadProductReviews(productId: 'prod-123')),
      expect: () => [
        isA<ReviewState>()
            .having((s) => s.status, 'status', ReviewStatus.loading)
            .having((s) => s.productId, 'productId', 'prod-123'),
        isA<ReviewState>()
            .having((s) => s.status, 'status', ReviewStatus.loaded)
            .having((s) => s.reviews.length, 'reviews.length', 1)
            .having((s) => s.averageRating, 'averageRating', 5.0)
            .having((s) => s.reviewCount, 'reviewCount', 1),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [submitting, success, loading, loaded] when SubmitReview succeeds',
      build: () {
        when(
          () => mockCreateReviewUseCase(
            productId: any(named: 'productId'),
            rating: any(named: 'rating'),
            title: any(named: 'title'),
            comment: any(named: 'comment'),
          ),
        ).thenAnswer((_) async => Success(sampleReview));

        when(
          () => mockGetProductReviewsUseCase(
            productId: any(named: 'productId'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            rating: any(named: 'rating'),
            verifiedOnly: any(named: 'verifiedOnly'),
          ),
        ).thenAnswer((_) async => Success(samplePaginated));

        return reviewBloc;
      },
      act: (bloc) => bloc.add(
        const SubmitReview(
          productId: 'prod-123',
          rating: 5,
          title: 'Outstanding quality!',
          comment: 'Exceeded all expectations.',
        ),
      ),
      expect: () => [
        isA<ReviewState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          ReviewActionStatus.submitting,
        ),
        isA<ReviewState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          ReviewActionStatus.success,
        ),
        isA<ReviewState>().having(
          (s) => s.status,
          'status',
          ReviewStatus.loading,
        ),
        isA<ReviewState>()
            .having((s) => s.status, 'status', ReviewStatus.loaded)
            .having((s) => s.reviews.length, 'reviews', 1),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [submitting, error] when SubmitReview fails (e.g. non-verified purchase)',
      build: () {
        when(
          () => mockCreateReviewUseCase(
            productId: any(named: 'productId'),
            rating: any(named: 'rating'),
            title: any(named: 'title'),
            comment: any(named: 'comment'),
          ),
        ).thenAnswer(
          (_) async => const Error(
            ServerFailure(
              message:
                  'You can only review products from completed, delivered purchases.',
            ),
          ),
        );
        return reviewBloc;
      },
      act: (bloc) => bloc.add(
        const SubmitReview(
          productId: 'prod-123',
          rating: 5,
          title: 'My Review',
        ),
      ),
      expect: () => [
        isA<ReviewState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          ReviewActionStatus.submitting,
        ),
        isA<ReviewState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              ReviewActionStatus.error,
            )
            .having(
              (s) => s.actionErrorMessage,
              'actionErrorMessage',
              'You can only review products from completed, delivered purchases.',
            ),
      ],
    );
  });
}
