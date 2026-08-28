import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/checkout_usecase.dart';
import '../../domain/usecases/get_order_details_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc({
    required this.checkoutUseCase,
    required this.getOrdersUseCase,
    required this.getOrderDetailsUseCase,
    required this.cancelOrderUseCase,
  }) : super(const OrderInitial()) {
    on<CheckoutSubmitted>(_onCheckoutSubmitted);
    on<OrdersRequested>(_onOrdersRequested);
    on<OrdersRefreshed>(_onOrdersRefreshed);
    on<OrderDetailsRequested>(_onOrderDetailsRequested);
    on<OrderCancelled>(_onOrderCancelled);
    on<OrdersReset>(_onOrdersReset);
  }

  final CheckoutUseCase checkoutUseCase;
  final GetOrdersUseCase getOrdersUseCase;
  final GetOrderDetailsUseCase getOrderDetailsUseCase;
  final CancelOrderUseCase cancelOrderUseCase;

  String _generateIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'key-$timestamp-$random';
  }

  Future<void> _onCheckoutSubmitted(
    CheckoutSubmitted event,
    Emitter<OrderState> emit,
  ) async {
    emit(const CheckoutLoading());
    final idempotencyKey = _generateIdempotencyKey();

    final result = await checkoutUseCase(
      shippingAddress: event.shippingAddress,
      customerNote: event.customerNote,
      idempotencyKey: idempotencyKey,
    );

    result.fold(
      onSuccess: (order) => emit(CheckoutSuccess(order)),
      onError: (failure) => emit(OrderFailure(failure.message)),
    );
  }

  Future<void> _onOrdersRequested(
    OrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await getOrdersUseCase(
      status: event.status,
      search: event.search,
      sort: event.sort,
      fromDate: event.fromDate,
      toDate: event.toDate,
    );

    result.fold(
      onSuccess: (orders) =>
          emit(OrdersLoaded(orders: orders, selectedFilter: event.status)),
      onError: (failure) => emit(OrderFailure(failure.message)),
    );
  }

  Future<void> _onOrdersRefreshed(
    OrdersRefreshed event,
    Emitter<OrderState> emit,
  ) async {
    final result = await getOrdersUseCase(
      status: event.status,
      search: event.search,
      sort: event.sort,
      fromDate: event.fromDate,
      toDate: event.toDate,
    );

    result.fold(
      onSuccess: (orders) =>
          emit(OrdersLoaded(orders: orders, selectedFilter: event.status)),
      onError: (failure) => emit(OrderFailure(failure.message)),
    );
  }

  Future<void> _onOrderDetailsRequested(
    OrderDetailsRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    final result = await getOrderDetailsUseCase(event.orderId);

    result.fold(
      onSuccess: (order) => emit(OrderDetailsLoaded(order: order)),
      onError: (failure) => emit(OrderFailure(failure.message)),
    );
  }

  Future<void> _onOrderCancelled(
    OrderCancelled event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrderDetailsLoaded) {
      final current = state as OrderDetailsLoaded;
      emit(current.copyWith(isCancelling: true));

      final result = await cancelOrderUseCase(event.orderId);

      await result.fold(
        onSuccess: (_) async {
          // Re-fetch order details to display fresh cancelled status
          final detailsResult = await getOrderDetailsUseCase(event.orderId);
          detailsResult.fold(
            onSuccess: (updatedOrder) => emit(
              OrderDetailsLoaded(
                order: updatedOrder,
                isCancelling: false,
                cancellationSuccess: true,
              ),
            ),
            onError: (failure) => emit(current.copyWith(isCancelling: false)),
          );
        },
        onError: (failure) async {
          emit(current.copyWith(isCancelling: false));
          emit(OrderFailure(failure.message));
        },
      );
    }
  }

  void _onOrdersReset(OrdersReset event, Emitter<OrderState> emit) {
    emit(const OrderInitial());
  }
}
