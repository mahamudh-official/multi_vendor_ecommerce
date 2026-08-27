import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';

sealed class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

final class OrderInitial extends OrderState {
  const OrderInitial();
}

final class OrderLoading extends OrderState {
  const OrderLoading();
}

final class CheckoutLoading extends OrderState {
  const CheckoutLoading();
}

final class CheckoutSuccess extends OrderState {
  const CheckoutSuccess(this.order);

  final Order order;

  @override
  List<Object?> get props => [order];
}

final class OrdersLoaded extends OrderState {
  const OrdersLoaded({required this.orders, this.selectedFilter});

  final List<Order> orders;
  final OrderStatus? selectedFilter;

  @override
  List<Object?> get props => [orders, selectedFilter];
}

final class OrderDetailsLoaded extends OrderState {
  const OrderDetailsLoaded({
    required this.order,
    this.isCancelling = false,
    this.cancellationSuccess = false,
  });

  final Order order;
  final bool isCancelling;
  final bool cancellationSuccess;

  OrderDetailsLoaded copyWith({
    Order? order,
    bool? isCancelling,
    bool? cancellationSuccess,
  }) {
    return OrderDetailsLoaded(
      order: order ?? this.order,
      isCancelling: isCancelling ?? this.isCancelling,
      cancellationSuccess: cancellationSuccess ?? this.cancellationSuccess,
    );
  }

  @override
  List<Object?> get props => [order, isCancelling, cancellationSuccess];
}

final class OrderFailure extends OrderState {
  const OrderFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
