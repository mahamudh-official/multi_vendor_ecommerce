import 'package:multi_vendor_ecommerce/features/payment/domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.userId,
    required super.amount,
    required super.currency,
    required super.status,
    required super.provider,
    super.providerPaymentId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount'] as String) ?? 0.0
          : (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: PaymentStatus.fromString(json['status'] as String),
      provider: json['provider'] as String? ?? 'mock',
      providerPaymentId: json['provider_payment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class PaymentIntentResultModel extends PaymentIntentResult {
  const PaymentIntentResultModel({
    required super.paymentId,
    required super.orderId,
    required super.amount,
    required super.currency,
    required super.status,
    required super.provider,
    super.providerPaymentId,
    super.clientSecret,
  });

  factory PaymentIntentResultModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResultModel(
      paymentId: json['payment_id'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount'] as String) ?? 0.0
          : (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: PaymentStatus.fromString(json['status'] as String),
      provider: json['provider'] as String? ?? 'mock',
      providerPaymentId: json['provider_payment_id'] as String?,
      clientSecret: json['client_secret'] as String?,
    );
  }
}

class PaymentProcessResultModel extends PaymentProcessResult {
  const PaymentProcessResultModel({
    required super.success,
    required super.payment,
    required super.message,
    super.transactionId,
  });

  factory PaymentProcessResultModel.fromJson(Map<String, dynamic> json) {
    return PaymentProcessResultModel(
      success: json['success'] as bool,
      payment: PaymentModel.fromJson(json['payment'] as Map<String, dynamic>),
      message: json['message'] as String? ?? 'Payment processed',
      transactionId: json['transaction_id'] as String?,
    );
  }
}
