import 'package:equatable/equatable.dart';

import '../../domain/entities/order_status.dart';
import '../../domain/entities/shipping_address.dart';

sealed class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

final class CheckoutSubmitted extends OrderEvent {
  const CheckoutSubmitted({required this.shippingAddress, this.customerNote});

  final ShippingAddress shippingAddress;
  final String? customerNote;

  @override
  List<Object?> get props => [shippingAddress, customerNote];
}

final class OrdersRequested extends OrderEvent {
  const OrdersRequested({this.status});

  final OrderStatus? status;

  @override
  List<Object?> get props => [status];
}

final class OrdersRefreshed extends OrderEvent {
  const OrdersRefreshed({this.status});

  final OrderStatus? status;

  @override
  List<Object?> get props => [status];
}

final class OrderDetailsRequested extends OrderEvent {
  const OrderDetailsRequested(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

final class OrderCancelled extends OrderEvent {
  const OrderCancelled(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

final class OrdersReset extends OrderEvent {
  const OrdersReset();
}
