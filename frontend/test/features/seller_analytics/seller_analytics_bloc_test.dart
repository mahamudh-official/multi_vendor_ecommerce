import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/entities/seller_analytics.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/usecases/seller_analytics_usecases.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_event.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_state.dart';

class MockGetSellerAnalyticsOverviewUseCase extends Mock implements GetSellerAnalyticsOverviewUseCase {}
class MockGetSellerSalesAnalyticsUseCase extends Mock implements GetSellerSalesAnalyticsUseCase {}
class MockGetSellerProductAnalyticsUseCase extends Mock implements GetSellerProductAnalyticsUseCase {}

void main() {
  late MockGetSellerAnalyticsOverviewUseCase mockOverviewUseCase;
  late MockGetSellerSalesAnalyticsUseCase mockSalesUseCase;
  late MockGetSellerProductAnalyticsUseCase mockProductUseCase;
  late SellerAnalyticsBloc analyticsBloc;

  const sampleOverview = SellerAnalyticsOverview(
    totalRevenue: 1500.0,
    totalOrders: 10,
    totalItemsSold: 25,
    averageOrderValue: 150.0,
    activeProducts: 5,
    lowStockProducts: 1,
    pendingFulfillmentCount: 2,
    deliveredOrderCount: 8,
  );

  const sampleTimeline = [
    SellerSalesPeriodItem(period: '2026-08-28', orderCount: 2, itemQuantity: 5, revenue: 300.0),
  ];

  const sampleProducts = [
    SellerProductAnalyticsItem(
      productId: 'prod-1',
      productName: 'Mechanical Keyboard',
      revenue: 600.0,
      quantitySold: 4,
      currentStock: 16,
      averageRating: 4.8,
      reviewCount: 12,
    ),
  ];

  setUp(() {
    mockOverviewUseCase = MockGetSellerAnalyticsOverviewUseCase();
    mockSalesUseCase = MockGetSellerSalesAnalyticsUseCase();
    mockProductUseCase = MockGetSellerProductAnalyticsUseCase();

    analyticsBloc = SellerAnalyticsBloc(
      getOverviewUseCase: mockOverviewUseCase,
      getSalesAnalyticsUseCase: mockSalesUseCase,
      getProductAnalyticsUseCase: mockProductUseCase,
    );
  });

  tearDown(() {
    analyticsBloc.close();
  });

  test('initial state should be SellerAnalyticsInitial', () {
    expect(analyticsBloc.state, isA<SellerAnalyticsInitial>());
  });

  blocTest<SellerAnalyticsBloc, SellerAnalyticsState>(
    'emits [SellerAnalyticsLoading, SellerAnalyticsLoaded] when LoadSellerAnalyticsEvent succeeds',
    build: () {
      when(() => mockOverviewUseCase()).thenAnswer((_) async => const Success(sampleOverview));
      when(() => mockSalesUseCase(period: any(named: 'period'))).thenAnswer((_) async => const Success(sampleTimeline));
      when(() => mockProductUseCase(limit: any(named: 'limit'))).thenAnswer((_) async => const Success(sampleProducts));
      return analyticsBloc;
    },
    act: (bloc) => bloc.add(const LoadSellerAnalyticsEvent(period: 'daily')),
    expect: () => [
      isA<SellerAnalyticsLoading>(),
      const SellerAnalyticsLoaded(
        overview: sampleOverview,
        salesTimeline: sampleTimeline,
        topProducts: sampleProducts,
        activePeriod: 'daily',
      ),
    ],
  );

  blocTest<SellerAnalyticsBloc, SellerAnalyticsState>(
    'emits [SellerAnalyticsLoading, SellerAnalyticsError] when overview fails',
    build: () {
      when(() => mockOverviewUseCase()).thenAnswer((_) async => const Error(ServerFailure(message: 'Unauthorized')));
      when(() => mockSalesUseCase(period: any(named: 'period'))).thenAnswer((_) async => const Success(sampleTimeline));
      when(() => mockProductUseCase(limit: any(named: 'limit'))).thenAnswer((_) async => const Success(sampleProducts));
      return analyticsBloc;
    },
    act: (bloc) => bloc.add(const LoadSellerAnalyticsEvent()),
    expect: () => [
      isA<SellerAnalyticsLoading>(),
      const SellerAnalyticsError('Unauthorized'),
    ],
  );
}
