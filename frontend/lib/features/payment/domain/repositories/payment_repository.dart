import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/entities/payment.dart';

abstract class PaymentRepository {
  Future<Result<PaymentIntentResult>> createPaymentIntent({
    required String orderId,
  });

  Future<Result<PaymentProcessResult>> processPayment({
    required String paymentId,
    bool simulateFailure = false,
  });

  Future<Result<Payment>> getPayment({required String paymentId});

  Future<Result<Payment>> getOrderPayment({required String orderId});
}
