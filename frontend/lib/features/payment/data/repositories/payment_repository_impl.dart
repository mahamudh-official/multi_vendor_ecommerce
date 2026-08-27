import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/entities/payment.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<PaymentIntentResult>> createPaymentIntent({
    required String orderId,
  }) async {
    try {
      final result = await remoteDataSource.createPaymentIntent(
        orderId: orderId,
      );
      return Success(result);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<PaymentProcessResult>> processPayment({
    required String paymentId,
    bool simulateFailure = false,
  }) async {
    try {
      final result = await remoteDataSource.processPayment(
        paymentId: paymentId,
        simulateFailure: simulateFailure,
      );
      return Success(result);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Payment>> getPayment({required String paymentId}) async {
    try {
      final result = await remoteDataSource.getPayment(paymentId: paymentId);
      return Success(result);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Payment>> getOrderPayment({required String orderId}) async {
    try {
      final result = await remoteDataSource.getOrderPayment(orderId: orderId);
      return Success(result);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
