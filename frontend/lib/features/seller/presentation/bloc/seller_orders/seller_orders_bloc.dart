import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_order.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/usecases/seller_order_usecases.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class SellerOrdersEvent extends Equatable {
  const SellerOrdersEvent();

  @override
  List<Object?> get props => [];
}

class SellerOrdersRequested extends SellerOrdersEvent {
  final String? status;
  final String? search;
  final int page;
  final int pageSize;

  const SellerOrdersRequested({
    this.status,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [status, search, page, pageSize];
}

class SellerOrderDetailsRequested extends SellerOrdersEvent {
  final String orderId;

  const SellerOrderDetailsRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class SellerOrderStatusUpdated extends SellerOrdersEvent {
  final String orderId;
  final FulfillmentStatus status;

  const SellerOrderStatusUpdated({required this.orderId, required this.status});

  @override
  List<Object?> get props => [orderId, status];
}

class SellerOrdersReset extends SellerOrdersEvent {
  const SellerOrdersReset();
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class SellerOrdersState extends Equatable {
  const SellerOrdersState();

  @override
  List<Object?> get props => [];
}

class SellerOrdersInitial extends SellerOrdersState {
  const SellerOrdersInitial();
}

class SellerOrdersLoading extends SellerOrdersState {
  const SellerOrdersLoading();
}

class SellerOrdersLoaded extends SellerOrdersState {
  final List<SellerOrder> orders;
  final int page;
  final bool hasMore;

  const SellerOrdersLoaded({
    required this.orders,
    this.page = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [orders, page, hasMore];
}

class SellerOrderDetailsLoaded extends SellerOrdersState {
  final SellerOrder order;

  const SellerOrderDetailsLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

class SellerOrderStatusUpdating extends SellerOrdersState {
  const SellerOrderStatusUpdating();
}

class SellerOrderStatusUpdateSuccess extends SellerOrdersState {
  final String message;
  final SellerOrder updatedOrder;

  const SellerOrderStatusUpdateSuccess({
    required this.message,
    required this.updatedOrder,
  });

  @override
  List<Object?> get props => [message, updatedOrder];
}

class SellerOrdersFailure extends SellerOrdersState {
  final String message;

  const SellerOrdersFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class SellerOrdersBloc extends Bloc<SellerOrdersEvent, SellerOrdersState> {
  final GetSellerOrdersUseCase getOrdersUseCase;
  final GetSellerOrderDetailsUseCase getOrderDetailsUseCase;
  final UpdateSellerOrderStatusUseCase updateOrderStatusUseCase;

  SellerOrdersBloc({
    required this.getOrdersUseCase,
    required this.getOrderDetailsUseCase,
    required this.updateOrderStatusUseCase,
  }) : super(const SellerOrdersInitial()) {
    on<SellerOrdersRequested>(_onOrdersRequested);
    on<SellerOrderDetailsRequested>(_onOrderDetailsRequested);
    on<SellerOrderStatusUpdated>(_onOrderStatusUpdated);
    on<SellerOrdersReset>(_onOrdersReset);
  }

  Future<void> _onOrdersRequested(
    SellerOrdersRequested event,
    Emitter<SellerOrdersState> emit,
  ) async {
    emit(const SellerOrdersLoading());
    final result = await getOrdersUseCase(
      status: event.status,
      search: event.search,
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      onSuccess: (orders) => emit(
        SellerOrdersLoaded(
          orders: orders,
          page: event.page,
          hasMore: orders.length >= event.pageSize,
        ),
      ),
      onError: (failure) => emit(SellerOrdersFailure(message: failure.message)),
    );
  }

  Future<void> _onOrderDetailsRequested(
    SellerOrderDetailsRequested event,
    Emitter<SellerOrdersState> emit,
  ) async {
    emit(const SellerOrdersLoading());
    final result = await getOrderDetailsUseCase(event.orderId);
    result.fold(
      onSuccess: (order) => emit(SellerOrderDetailsLoaded(order: order)),
      onError: (failure) => emit(SellerOrdersFailure(message: failure.message)),
    );
  }

  Future<void> _onOrderStatusUpdated(
    SellerOrderStatusUpdated event,
    Emitter<SellerOrdersState> emit,
  ) async {
    emit(const SellerOrderStatusUpdating());
    final result = await updateOrderStatusUseCase(
      orderId: event.orderId,
      status: event.status,
    );

    result.fold(
      onSuccess: (order) {
        emit(
          SellerOrderStatusUpdateSuccess(
            message: 'Status updated to ${event.status.displayName}',
            updatedOrder: order,
          ),
        );
        emit(SellerOrderDetailsLoaded(order: order));
      },
      onError: (failure) => emit(SellerOrdersFailure(message: failure.message)),
    );
  }

  void _onOrdersReset(
    SellerOrdersReset event,
    Emitter<SellerOrdersState> emit,
  ) {
    emit(const SellerOrdersInitial());
  }
}
