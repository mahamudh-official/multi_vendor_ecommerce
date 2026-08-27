import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PaymentStatus {
  pending('pending', 'Pending', Colors.orange),
  processing('processing', 'Processing', Colors.blue),
  succeeded('succeeded', 'Succeeded', Colors.green),
  failed('failed', 'Failed', Colors.red),
  cancelled('cancelled', 'Cancelled', Colors.grey);

  final String value;
  final String label;
  final Color color;

  const PaymentStatus(this.value, this.label, this.color);

  static PaymentStatus fromString(String status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == status.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}

class Payment extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String provider;
  final String? providerPaymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    this.providerPaymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    orderId,
    userId,
    amount,
    currency,
    status,
    provider,
    providerPaymentId,
    createdAt,
    updatedAt,
  ];
}

class PaymentIntentResult extends Equatable {
  final String paymentId;
  final String orderId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String provider;
  final String? providerPaymentId;
  final String? clientSecret;

  const PaymentIntentResult({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    this.providerPaymentId,
    this.clientSecret,
  });

  @override
  List<Object?> get props => [
    paymentId,
    orderId,
    amount,
    currency,
    status,
    provider,
    providerPaymentId,
    clientSecret,
  ];
}

class PaymentProcessResult extends Equatable {
  final bool success;
  final Payment payment;
  final String message;
  final String? transactionId;

  const PaymentProcessResult({
    required this.success,
    required this.payment,
    required this.message,
    this.transactionId,
  });

  @override
  List<Object?> get props => [success, payment, message, transactionId];
}
