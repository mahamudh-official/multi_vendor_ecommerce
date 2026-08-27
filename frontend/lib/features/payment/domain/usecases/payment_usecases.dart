import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/entities/payment.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/repositories/payment_repository.dart';

class CreatePaymentUseCase {
  final PaymentRepository repository;

  CreatePaymentUseCase(this.repository);

  Future<Result<PaymentIntentResult>> call(String orderId) {
    return repository.createPaymentIntent(orderId: orderId);
  }
}

class ProcessPaymentUseCase {
  final PaymentRepository repository;

  ProcessPaymentUseCase(this.repository);

  Future<Result<PaymentProcessResult>> call({
    required String paymentId,
    bool simulateFailure = false,
  }) {
    return repository.processPayment(
      paymentId: paymentId,
      simulateFailure: simulateFailure,
    );
  }
}

class GetPaymentUseCase {
  final PaymentRepository repository;

  GetPaymentUseCase(this.repository);

  Future<Result<Payment>> call(String paymentId) {
    return repository.getPayment(paymentId: paymentId);
  }
}

class GetOrderPaymentUseCase {
  final PaymentRepository repository;

  GetOrderPaymentUseCase(this.repository);

  Future<Result<Payment>> call(String orderId) {
    return repository.getOrderPayment(orderId: orderId);
  }
}
