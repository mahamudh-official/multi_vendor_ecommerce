import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_entities.dart';
import '../../domain/usecases/admin_usecases.dart';

// ── 1. Admin Dashboard BLoC ──────────────────────────────────────────────────

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();
  @override
  List<Object?> get props => [];
}

class AdminDashboardLoadRequested extends AdminDashboardEvent {}

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminDashboardStats stats;
  const AdminDashboardLoaded({required this.stats});
  @override
  List<Object?> get props => [stats];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final GetAdminDashboardStatsUseCase getDashboardStatsUseCase;

  AdminDashboardBloc({required this.getDashboardStatsUseCase})
    : super(AdminDashboardInitial()) {
    on<AdminDashboardLoadRequested>((event, emit) async {
      emit(AdminDashboardLoading());
      final result = await getDashboardStatsUseCase();
      result.fold(
        onError: (failure) =>
            emit(AdminDashboardError(message: failure.message)),
        onSuccess: (stats) => emit(AdminDashboardLoaded(stats: stats)),
      );
    });
  }
}

// ── 2. Admin Users BLoC ──────────────────────────────────────────────────────

abstract class AdminUsersEvent extends Equatable {
  const AdminUsersEvent();
  @override
  List<Object?> get props => [];
}

class AdminUsersLoadRequested extends AdminUsersEvent {
  final String? search;
  final String? role;
  final bool? isActive;
  final int page;

  const AdminUsersLoadRequested({
    this.search,
    this.role,
    this.isActive,
    this.page = 1,
  });

  @override
  List<Object?> get props => [search, role, isActive, page];
}

class AdminUserStatusUpdateRequested extends AdminUsersEvent {
  final String userId;
  final bool isActive;

  const AdminUserStatusUpdateRequested({
    required this.userId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [userId, isActive];
}

abstract class AdminUsersState extends Equatable {
  const AdminUsersState();
  @override
  List<Object?> get props => [];
}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<AdminUser> users;
  final String? currentSearch;
  final String? currentRole;
  final bool? currentIsActive;

  const AdminUsersLoaded({
    required this.users,
    this.currentSearch,
    this.currentRole,
    this.currentIsActive,
  });

  @override
  List<Object?> get props => [
    users,
    currentSearch,
    currentRole,
    currentIsActive,
  ];
}

class AdminUsersError extends AdminUsersState {
  final String message;
  const AdminUsersError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  final GetAdminUsersUseCase getUsersUseCase;
  final UpdateAdminUserStatusUseCase updateUserStatusUseCase;

  AdminUsersBloc({
    required this.getUsersUseCase,
    required this.updateUserStatusUseCase,
  }) : super(AdminUsersInitial()) {
    on<AdminUsersLoadRequested>((event, emit) async {
      emit(AdminUsersLoading());
      final result = await getUsersUseCase(
        search: event.search,
        role: event.role,
        isActive: event.isActive,
        page: event.page,
      );
      result.fold(
        onError: (failure) => emit(AdminUsersError(message: failure.message)),
        onSuccess: (users) => emit(
          AdminUsersLoaded(
            users: users,
            currentSearch: event.search,
            currentRole: event.role,
            currentIsActive: event.isActive,
          ),
        ),
      );
    });

    on<AdminUserStatusUpdateRequested>((event, emit) async {
      final result = await updateUserStatusUseCase(
        userId: event.userId,
        isActive: event.isActive,
      );
      result.fold(
        onError: (failure) => emit(AdminUsersError(message: failure.message)),
        onSuccess: (updatedUser) {
          if (state is AdminUsersLoaded) {
            final current = (state as AdminUsersLoaded).users;
            final updated = current
                .map((u) => u.id == updatedUser.id ? updatedUser : u)
                .toList();
            emit(
              AdminUsersLoaded(
                users: updated,
                currentSearch: (state as AdminUsersLoaded).currentSearch,
                currentRole: (state as AdminUsersLoaded).currentRole,
                currentIsActive: (state as AdminUsersLoaded).currentIsActive,
              ),
            );
          }
        },
      );
    });
  }
}

// ── 3. Admin Sellers BLoC ────────────────────────────────────────────────────

abstract class AdminSellersEvent extends Equatable {
  const AdminSellersEvent();
  @override
  List<Object?> get props => [];
}

class AdminSellersLoadRequested extends AdminSellersEvent {
  final String? search;
  final String? sellerStatus;
  final int page;

  const AdminSellersLoadRequested({
    this.search,
    this.sellerStatus,
    this.page = 1,
  });

  @override
  List<Object?> get props => [search, sellerStatus, page];
}

class AdminSellerStatusUpdateRequested extends AdminSellersEvent {
  final String sellerId;
  final String status;

  const AdminSellerStatusUpdateRequested({
    required this.sellerId,
    required this.status,
  });

  @override
  List<Object?> get props => [sellerId, status];
}

abstract class AdminSellersState extends Equatable {
  const AdminSellersState();
  @override
  List<Object?> get props => [];
}

class AdminSellersInitial extends AdminSellersState {}

class AdminSellersLoading extends AdminSellersState {}

class AdminSellersLoaded extends AdminSellersState {
  final List<AdminSeller> sellers;
  final String? currentSearch;
  final String? currentSellerStatus;

  const AdminSellersLoaded({
    required this.sellers,
    this.currentSearch,
    this.currentSellerStatus,
  });

  @override
  List<Object?> get props => [sellers, currentSearch, currentSellerStatus];
}

class AdminSellersError extends AdminSellersState {
  final String message;
  const AdminSellersError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminSellersBloc extends Bloc<AdminSellersEvent, AdminSellersState> {
  final GetAdminSellersUseCase getSellersUseCase;
  final UpdateAdminSellerStatusUseCase updateSellerStatusUseCase;

  AdminSellersBloc({
    required this.getSellersUseCase,
    required this.updateSellerStatusUseCase,
  }) : super(AdminSellersInitial()) {
    on<AdminSellersLoadRequested>((event, emit) async {
      emit(AdminSellersLoading());
      final result = await getSellersUseCase(
        search: event.search,
        sellerStatus: event.sellerStatus,
        page: event.page,
      );
      result.fold(
        onError: (failure) => emit(AdminSellersError(message: failure.message)),
        onSuccess: (sellers) => emit(
          AdminSellersLoaded(
            sellers: sellers,
            currentSearch: event.search,
            currentSellerStatus: event.sellerStatus,
          ),
        ),
      );
    });

    on<AdminSellerStatusUpdateRequested>((event, emit) async {
      final result = await updateSellerStatusUseCase(
        sellerId: event.sellerId,
        status: event.status,
      );
      result.fold(
        onError: (failure) => emit(AdminSellersError(message: failure.message)),
        onSuccess: (updatedSeller) {
          if (state is AdminSellersLoaded) {
            final current = (state as AdminSellersLoaded).sellers;
            final updated = current
                .map((s) => s.id == updatedSeller.id ? updatedSeller : s)
                .toList();
            emit(
              AdminSellersLoaded(
                sellers: updated,
                currentSearch: (state as AdminSellersLoaded).currentSearch,
                currentSellerStatus:
                    (state as AdminSellersLoaded).currentSellerStatus,
              ),
            );
          }
        },
      );
    });
  }
}

// ── 4. Admin Products BLoC ───────────────────────────────────────────────────

abstract class AdminProductsEvent extends Equatable {
  const AdminProductsEvent();
  @override
  List<Object?> get props => [];
}

class AdminProductsLoadRequested extends AdminProductsEvent {
  final String? sellerId;
  final String? categoryId;
  final bool? isActive;
  final bool? lowStock;
  final String? search;
  final int page;

  const AdminProductsLoadRequested({
    this.sellerId,
    this.categoryId,
    this.isActive,
    this.lowStock,
    this.search,
    this.page = 1,
  });

  @override
  List<Object?> get props => [
    sellerId,
    categoryId,
    isActive,
    lowStock,
    search,
    page,
  ];
}

class AdminProductStatusUpdateRequested extends AdminProductsEvent {
  final String productId;
  final bool isActive;

  const AdminProductStatusUpdateRequested({
    required this.productId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [productId, isActive];
}

abstract class AdminProductsState extends Equatable {
  const AdminProductsState();
  @override
  List<Object?> get props => [];
}

class AdminProductsInitial extends AdminProductsState {}

class AdminProductsLoading extends AdminProductsState {}

class AdminProductsLoaded extends AdminProductsState {
  final List<AdminProduct> products;
  const AdminProductsLoaded({required this.products});
  @override
  List<Object?> get props => [products];
}

class AdminProductsError extends AdminProductsState {
  final String message;
  const AdminProductsError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminProductsBloc extends Bloc<AdminProductsEvent, AdminProductsState> {
  final GetAdminProductsUseCase getProductsUseCase;
  final UpdateAdminProductStatusUseCase updateProductStatusUseCase;

  AdminProductsBloc({
    required this.getProductsUseCase,
    required this.updateProductStatusUseCase,
  }) : super(AdminProductsInitial()) {
    on<AdminProductsLoadRequested>((event, emit) async {
      emit(AdminProductsLoading());
      final result = await getProductsUseCase(
        sellerId: event.sellerId,
        categoryId: event.categoryId,
        isActive: event.isActive,
        lowStock: event.lowStock,
        search: event.search,
        page: event.page,
      );
      result.fold(
        onError: (failure) =>
            emit(AdminProductsError(message: failure.message)),
        onSuccess: (products) => emit(AdminProductsLoaded(products: products)),
      );
    });

    on<AdminProductStatusUpdateRequested>((event, emit) async {
      final result = await updateProductStatusUseCase(
        productId: event.productId,
        isActive: event.isActive,
      );
      result.fold(
        onError: (failure) =>
            emit(AdminProductsError(message: failure.message)),
        onSuccess: (updatedProduct) {
          if (state is AdminProductsLoaded) {
            final current = (state as AdminProductsLoaded).products;
            final updated = current
                .map((p) => p.id == updatedProduct.id ? updatedProduct : p)
                .toList();
            emit(AdminProductsLoaded(products: updated));
          }
        },
      );
    });
  }
}

// ── 5. Admin Categories BLoC ─────────────────────────────────────────────────

abstract class AdminCategoriesEvent extends Equatable {
  const AdminCategoriesEvent();
  @override
  List<Object?> get props => [];
}

class AdminCategoriesLoadRequested extends AdminCategoriesEvent {}

class AdminCategoryCreateRequested extends AdminCategoriesEvent {
  final String name;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  const AdminCategoryCreateRequested({
    required this.name,
    this.slug,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, slug, description, imageUrl, isActive];
}

class AdminCategoryUpdateRequested extends AdminCategoriesEvent {
  final String categoryId;
  final String? name;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final bool? isActive;

  const AdminCategoryUpdateRequested({
    required this.categoryId,
    this.name,
    this.slug,
    this.description,
    this.imageUrl,
    this.isActive,
  });

  @override
  List<Object?> get props => [
    categoryId,
    name,
    slug,
    description,
    imageUrl,
    isActive,
  ];
}

class AdminCategoryDeleteRequested extends AdminCategoriesEvent {
  final String categoryId;
  const AdminCategoryDeleteRequested(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

abstract class AdminCategoriesState extends Equatable {
  const AdminCategoriesState();
  @override
  List<Object?> get props => [];
}

class AdminCategoriesInitial extends AdminCategoriesState {}

class AdminCategoriesLoading extends AdminCategoriesState {}

class AdminCategoriesLoaded extends AdminCategoriesState {
  final List<AdminCategory> categories;
  const AdminCategoriesLoaded({required this.categories});
  @override
  List<Object?> get props => [categories];
}

class AdminCategoriesError extends AdminCategoriesState {
  final String message;
  const AdminCategoriesError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminCategoriesBloc
    extends Bloc<AdminCategoriesEvent, AdminCategoriesState> {
  final GetAdminCategoriesUseCase getCategoriesUseCase;
  final CreateAdminCategoryUseCase createCategoryUseCase;
  final UpdateAdminCategoryUseCase updateCategoryUseCase;
  final DeleteAdminCategoryUseCase deleteCategoryUseCase;

  AdminCategoriesBloc({
    required this.getCategoriesUseCase,
    required this.createCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
  }) : super(AdminCategoriesInitial()) {
    on<AdminCategoriesLoadRequested>((event, emit) async {
      emit(AdminCategoriesLoading());
      final result = await getCategoriesUseCase();
      result.fold(
        onError: (failure) =>
            emit(AdminCategoriesError(message: failure.message)),
        onSuccess: (categories) =>
            emit(AdminCategoriesLoaded(categories: categories)),
      );
    });

    on<AdminCategoryCreateRequested>((event, emit) async {
      emit(AdminCategoriesLoading());
      final result = await createCategoryUseCase(
        name: event.name,
        slug: event.slug,
        description: event.description,
        imageUrl: event.imageUrl,
        isActive: event.isActive,
      );
      result.fold(
        onError: (failure) =>
            emit(AdminCategoriesError(message: failure.message)),
        onSuccess: (_) => add(AdminCategoriesLoadRequested()),
      );
    });

    on<AdminCategoryUpdateRequested>((event, emit) async {
      emit(AdminCategoriesLoading());
      final result = await updateCategoryUseCase(
        categoryId: event.categoryId,
        name: event.name,
        slug: event.slug,
        description: event.description,
        imageUrl: event.imageUrl,
        isActive: event.isActive,
      );
      result.fold(
        onError: (failure) =>
            emit(AdminCategoriesError(message: failure.message)),
        onSuccess: (_) => add(AdminCategoriesLoadRequested()),
      );
    });

    on<AdminCategoryDeleteRequested>((event, emit) async {
      emit(AdminCategoriesLoading());
      final result = await deleteCategoryUseCase(event.categoryId);
      result.fold(
        onError: (failure) =>
            emit(AdminCategoriesError(message: failure.message)),
        onSuccess: (_) => add(AdminCategoriesLoadRequested()),
      );
    });
  }
}

// ── 6. Admin Orders BLoC ─────────────────────────────────────────────────────

abstract class AdminOrdersEvent extends Equatable {
  const AdminOrdersEvent();
  @override
  List<Object?> get props => [];
}

class AdminOrdersLoadRequested extends AdminOrdersEvent {
  final String? status;
  final String? paymentStatus;
  final String? customerId;
  final String? sellerId;
  final int page;

  const AdminOrdersLoadRequested({
    this.status,
    this.paymentStatus,
    this.customerId,
    this.sellerId,
    this.page = 1,
  });

  @override
  List<Object?> get props => [
    status,
    paymentStatus,
    customerId,
    sellerId,
    page,
  ];
}

class AdminOrderDetailsRequested extends AdminOrdersEvent {
  final String orderId;
  const AdminOrderDetailsRequested(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

abstract class AdminOrdersState extends Equatable {
  const AdminOrdersState();
  @override
  List<Object?> get props => [];
}

class AdminOrdersInitial extends AdminOrdersState {}

class AdminOrdersLoading extends AdminOrdersState {}

class AdminOrdersLoaded extends AdminOrdersState {
  final List<AdminOrder> orders;
  final AdminOrder? selectedOrder;

  const AdminOrdersLoaded({required this.orders, this.selectedOrder});

  @override
  List<Object?> get props => [orders, selectedOrder];
}

class AdminOrdersError extends AdminOrdersState {
  final String message;
  const AdminOrdersError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminOrdersBloc extends Bloc<AdminOrdersEvent, AdminOrdersState> {
  final GetAdminOrdersUseCase getOrdersUseCase;
  final GetAdminOrderDetailsUseCase getOrderDetailsUseCase;

  AdminOrdersBloc({
    required this.getOrdersUseCase,
    required this.getOrderDetailsUseCase,
  }) : super(AdminOrdersInitial()) {
    on<AdminOrdersLoadRequested>((event, emit) async {
      emit(AdminOrdersLoading());
      final result = await getOrdersUseCase(
        status: event.status,
        paymentStatus: event.paymentStatus,
        customerId: event.customerId,
        sellerId: event.sellerId,
        page: event.page,
      );
      result.fold(
        onError: (failure) => emit(AdminOrdersError(message: failure.message)),
        onSuccess: (orders) => emit(AdminOrdersLoaded(orders: orders)),
      );
    });

    on<AdminOrderDetailsRequested>((event, emit) async {
      emit(AdminOrdersLoading());
      final result = await getOrderDetailsUseCase(event.orderId);
      result.fold(
        onError: (failure) => emit(AdminOrdersError(message: failure.message)),
        onSuccess: (order) =>
            emit(AdminOrdersLoaded(orders: const [], selectedOrder: order)),
      );
    });
  }
}

// ── 7. Admin Payments BLoC ───────────────────────────────────────────────────

abstract class AdminPaymentsEvent extends Equatable {
  const AdminPaymentsEvent();
  @override
  List<Object?> get props => [];
}

class AdminPaymentsLoadRequested extends AdminPaymentsEvent {
  final String? status;
  final String? provider;
  final int page;

  const AdminPaymentsLoadRequested({this.status, this.provider, this.page = 1});

  @override
  List<Object?> get props => [status, provider, page];
}

abstract class AdminPaymentsState extends Equatable {
  const AdminPaymentsState();
  @override
  List<Object?> get props => [];
}

class AdminPaymentsInitial extends AdminPaymentsState {}

class AdminPaymentsLoading extends AdminPaymentsState {}

class AdminPaymentsLoaded extends AdminPaymentsState {
  final List<AdminPayment> payments;
  const AdminPaymentsLoaded({required this.payments});
  @override
  List<Object?> get props => [payments];
}

class AdminPaymentsError extends AdminPaymentsState {
  final String message;
  const AdminPaymentsError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminPaymentsBloc extends Bloc<AdminPaymentsEvent, AdminPaymentsState> {
  final GetAdminPaymentsUseCase getPaymentsUseCase;

  AdminPaymentsBloc({required this.getPaymentsUseCase})
    : super(AdminPaymentsInitial()) {
    on<AdminPaymentsLoadRequested>((event, emit) async {
      emit(AdminPaymentsLoading());
      final result = await getPaymentsUseCase(
        status: event.status,
        provider: event.provider,
        page: event.page,
      );
      result.fold(
        onError: (failure) =>
            emit(AdminPaymentsError(message: failure.message)),
        onSuccess: (payments) => emit(AdminPaymentsLoaded(payments: payments)),
      );
    });
  }
}

// ── 8. Admin Audit Logs BLoC ─────────────────────────────────────────────────

abstract class AdminAuditLogsEvent extends Equatable {
  const AdminAuditLogsEvent();
  @override
  List<Object?> get props => [];
}

class AdminAuditLogsLoadRequested extends AdminAuditLogsEvent {
  final String? adminUserId;
  final String? action;
  final String? entityType;
  final int page;

  const AdminAuditLogsLoadRequested({
    this.adminUserId,
    this.action,
    this.entityType,
    this.page = 1,
  });

  @override
  List<Object?> get props => [adminUserId, action, entityType, page];
}

abstract class AdminAuditLogsState extends Equatable {
  const AdminAuditLogsState();
  @override
  List<Object?> get props => [];
}

class AdminAuditLogsInitial extends AdminAuditLogsState {}

class AdminAuditLogsLoading extends AdminAuditLogsState {}

class AdminAuditLogsLoaded extends AdminAuditLogsState {
  final List<AdminAuditLog> logs;
  const AdminAuditLogsLoaded({required this.logs});
  @override
  List<Object?> get props => [logs];
}

class AdminAuditLogsError extends AdminAuditLogsState {
  final String message;
  const AdminAuditLogsError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AdminAuditLogsBloc
    extends Bloc<AdminAuditLogsEvent, AdminAuditLogsState> {
  final GetAdminAuditLogsUseCase getAuditLogsUseCase;

  AdminAuditLogsBloc({required this.getAuditLogsUseCase})
    : super(AdminAuditLogsInitial()) {
    on<AdminAuditLogsLoadRequested>((event, emit) async {
      emit(AdminAuditLogsLoading());
      final result = await getAuditLogsUseCase(
        adminUserId: event.adminUserId,
        action: event.action,
        entityType: event.entityType,
        page: event.page,
      );
      result.fold(
        onError: (failure) =>
            emit(AdminAuditLogsError(message: failure.message)),
        onSuccess: (logs) => emit(AdminAuditLogsLoaded(logs: logs)),
      );
    });
  }
}
