import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_dashboard_stats.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/usecases/get_seller_dashboard_usecase.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_dashboard/seller_dashboard_bloc.dart';

class MockGetSellerDashboardUseCase extends Mock
    implements GetSellerDashboardUseCase {}

void main() {
  late SellerDashboardBloc bloc;
  late MockGetSellerDashboardUseCase mockGetDashboardUseCase;

  const tStats = SellerDashboardStats(
    totalProducts: 10,
    activeProducts: 8,
    inactiveProducts: 2,
    lowStockProducts: 1,
    totalOrders: 15,
    pendingOrders: 3,
    processingOrders: 2,
    shippedOrders: 4,
    deliveredOrders: 6,
    totalSalesAmount: 1450.50,
  );

  const tDashboard = SellerDashboard(
    stats: tStats,
    recentOrders: [],
    lowStockProducts: [],
  );

  setUp(() {
    mockGetDashboardUseCase = MockGetSellerDashboardUseCase();
    bloc = SellerDashboardBloc(getDashboardUseCase: mockGetDashboardUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be SellerDashboardInitial', () {
    expect(bloc.state, const SellerDashboardInitial());
  });

  test('SellerDashboardRequested emits [Loading, Loaded] on success', () async {
    when(
      () => mockGetDashboardUseCase(),
    ).thenAnswer((_) async => const Success(tDashboard));

    expectLater(
      bloc.stream,
      emitsInOrder([
        const SellerDashboardLoading(),
        const SellerDashboardLoaded(dashboard: tDashboard),
      ]),
    );

    bloc.add(const SellerDashboardRequested());
  });

  test('SellerDashboardRequested emits [Loading, Failure] on error', () async {
    when(() => mockGetDashboardUseCase()).thenAnswer(
      (_) async => const Error(ServerFailure(message: 'Server error')),
    );

    expectLater(
      bloc.stream,
      emitsInOrder([
        const SellerDashboardLoading(),
        const SellerDashboardFailure(message: 'Server error'),
      ]),
    );

    bloc.add(const SellerDashboardRequested());
  });

  test('SellerDashboardReset emits SellerDashboardInitial', () async {
    expectLater(bloc.stream, emitsInOrder([const SellerDashboardInitial()]));

    bloc.add(const SellerDashboardReset());
  });
}
