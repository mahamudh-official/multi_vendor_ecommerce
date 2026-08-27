import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/admin/domain/entities/admin_entities.dart';
import 'package:multi_vendor_ecommerce/features/admin/domain/usecases/admin_usecases.dart';
import 'package:multi_vendor_ecommerce/features/admin/presentation/bloc/admin_blocs.dart';

class MockGetAdminDashboardStatsUseCase extends Mock
    implements GetAdminDashboardStatsUseCase {}

class MockGetAdminUsersUseCase extends Mock implements GetAdminUsersUseCase {}

class MockUpdateAdminUserStatusUseCase extends Mock
    implements UpdateAdminUserStatusUseCase {}

class MockGetAdminSellersUseCase extends Mock
    implements GetAdminSellersUseCase {}

class MockUpdateAdminSellerStatusUseCase extends Mock
    implements UpdateAdminSellerStatusUseCase {}

void main() {
  late MockGetAdminDashboardStatsUseCase mockGetDashboardStatsUseCase;
  late MockGetAdminUsersUseCase mockGetUsersUseCase;
  late MockUpdateAdminUserStatusUseCase mockUpdateUserStatusUseCase;

  const tStats = AdminDashboardStats(
    totalUsers: 10,
    totalCustomers: 8,
    totalSellers: 2,
    activeSellers: 2,
    pendingSellers: 0,
    totalProducts: 25,
    activeProducts: 20,
    inactiveProducts: 5,
    lowStockProducts: 3,
    totalOrders: 15,
    pendingOrders: 2,
    confirmedOrders: 3,
    processingOrders: 2,
    shippedOrders: 3,
    deliveredOrders: 4,
    cancelledOrders: 1,
    totalRevenue: 2500.00,
    todayRevenue: 300.00,
    monthRevenue: 1500.00,
    totalPayments: 15,
    successfulPayments: 14,
    failedPayments: 1,
  );

  final tUsers = [
    AdminUser(
      id: 'u1',
      fullName: 'Alice Admin',
      email: 'alice@admin.com',
      role: 'admin',
      isActive: true,
      createdAt: DateTime.parse('2026-08-28T00:00:00Z'),
      updatedAt: DateTime.parse('2026-08-28T00:00:00Z'),
    ),
    AdminUser(
      id: 'u2',
      fullName: 'Bob Buyer',
      email: 'bob@buyer.com',
      role: 'customer',
      isActive: true,
      createdAt: DateTime.parse('2026-08-28T00:00:00Z'),
      updatedAt: DateTime.parse('2026-08-28T00:00:00Z'),
    ),
  ];

  setUp(() {
    mockGetDashboardStatsUseCase = MockGetAdminDashboardStatsUseCase();
    mockGetUsersUseCase = MockGetAdminUsersUseCase();
    mockUpdateUserStatusUseCase = MockUpdateAdminUserStatusUseCase();
  });

  group('AdminDashboardBloc', () {
    blocTest<AdminDashboardBloc, AdminDashboardState>(
      'emits [AdminDashboardLoading, AdminDashboardLoaded] on successful stats fetch',
      build: () {
        when(
          () => mockGetDashboardStatsUseCase(),
        ).thenAnswer((_) async => const Success(tStats));
        return AdminDashboardBloc(
          getDashboardStatsUseCase: mockGetDashboardStatsUseCase,
        );
      },
      act: (bloc) => bloc.add(AdminDashboardLoadRequested()),
      expect: () => [
        AdminDashboardLoading(),
        const AdminDashboardLoaded(stats: tStats),
      ],
      verify: (_) {
        verify(() => mockGetDashboardStatsUseCase()).called(1);
      },
    );

    blocTest<AdminDashboardBloc, AdminDashboardState>(
      'emits [AdminDashboardLoading, AdminDashboardError] on failure',
      build: () {
        when(() => mockGetDashboardStatsUseCase()).thenAnswer(
          (_) async => const Error(ServerFailure(message: 'Server error')),
        );
        return AdminDashboardBloc(
          getDashboardStatsUseCase: mockGetDashboardStatsUseCase,
        );
      },
      act: (bloc) => bloc.add(AdminDashboardLoadRequested()),
      expect: () => [
        AdminDashboardLoading(),
        const AdminDashboardError(message: 'Server error'),
      ],
    );
  });

  group('AdminUsersBloc', () {
    blocTest<AdminUsersBloc, AdminUsersState>(
      'emits [AdminUsersLoading, AdminUsersLoaded] when users are fetched',
      build: () {
        when(
          () => mockGetUsersUseCase(
            search: any(named: 'search'),
            role: any(named: 'role'),
            isActive: any(named: 'isActive'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Success(tUsers));
        return AdminUsersBloc(
          getUsersUseCase: mockGetUsersUseCase,
          updateUserStatusUseCase: mockUpdateUserStatusUseCase,
        );
      },
      act: (bloc) => bloc.add(const AdminUsersLoadRequested()),
      expect: () => [AdminUsersLoading(), AdminUsersLoaded(users: tUsers)],
    );
  });
}
