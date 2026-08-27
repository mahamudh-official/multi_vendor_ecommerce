import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  processing('processing', 'Processing'),
  shipped('shipped', 'Shipped'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }

  bool get isCancellable =>
      this == OrderStatus.pending || this == OrderStatus.confirmed;

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColorsLight.warning;
      case OrderStatus.confirmed:
        return AppColorsLight.primary;
      case OrderStatus.processing:
        return Colors.indigo;
      case OrderStatus.shipped:
        return Colors.teal;
      case OrderStatus.delivered:
        return AppColorsLight.success;
      case OrderStatus.cancelled:
        return AppColorsLight.error;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
