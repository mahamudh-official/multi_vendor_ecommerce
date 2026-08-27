import 'package:flutter/material.dart';

enum FulfillmentStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled;

  static FulfillmentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return FulfillmentStatus.confirmed;
      case 'processing':
        return FulfillmentStatus.processing;
      case 'shipped':
        return FulfillmentStatus.shipped;
      case 'delivered':
        return FulfillmentStatus.delivered;
      case 'cancelled':
        return FulfillmentStatus.cancelled;
      case 'pending':
      default:
        return FulfillmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case FulfillmentStatus.pending:
        return 'Pending';
      case FulfillmentStatus.confirmed:
        return 'Confirmed';
      case FulfillmentStatus.processing:
        return 'Processing';
      case FulfillmentStatus.shipped:
        return 'Shipped';
      case FulfillmentStatus.delivered:
        return 'Delivered';
      case FulfillmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case FulfillmentStatus.pending:
        return const Color(0xFFF59E0B); // amber
      case FulfillmentStatus.confirmed:
        return const Color(0xFF3B82F6); // blue
      case FulfillmentStatus.processing:
        return const Color(0xFF8B5CF6); // purple
      case FulfillmentStatus.shipped:
        return const Color(0xFF06B6D4); // cyan
      case FulfillmentStatus.delivered:
        return const Color(0xFF10B981); // emerald
      case FulfillmentStatus.cancelled:
        return const Color(0xFFEF4444); // red
    }
  }

  IconData get icon {
    switch (this) {
      case FulfillmentStatus.pending:
        return Icons.hourglass_top_rounded;
      case FulfillmentStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case FulfillmentStatus.processing:
        return Icons.inventory_2_outlined;
      case FulfillmentStatus.shipped:
        return Icons.local_shipping_outlined;
      case FulfillmentStatus.delivered:
        return Icons.task_alt_rounded;
      case FulfillmentStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  FulfillmentStatus? get nextStatus {
    switch (this) {
      case FulfillmentStatus.pending:
        return FulfillmentStatus.confirmed;
      case FulfillmentStatus.confirmed:
        return FulfillmentStatus.processing;
      case FulfillmentStatus.processing:
        return FulfillmentStatus.shipped;
      case FulfillmentStatus.shipped:
        return FulfillmentStatus.delivered;
      case FulfillmentStatus.delivered:
      case FulfillmentStatus.cancelled:
        return null;
    }
  }

  String? get nextActionLabel {
    switch (this) {
      case FulfillmentStatus.pending:
        return 'Confirm Order';
      case FulfillmentStatus.confirmed:
        return 'Mark Processing';
      case FulfillmentStatus.processing:
        return 'Mark Shipped';
      case FulfillmentStatus.shipped:
        return 'Mark Delivered';
      case FulfillmentStatus.delivered:
      case FulfillmentStatus.cancelled:
        return null;
    }
  }
}
