import 'package:multi_vendor_ecommerce/core/network/dio_client.dart';
import 'package:multi_vendor_ecommerce/features/payment/data/models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentIntentResultModel> createPaymentIntent({
    required String orderId,
  });

  Future<PaymentProcessResultModel> processPayment({
    required String paymentId,
    bool simulateFailure = false,
  });

  Future<PaymentModel> getPayment({required String paymentId});

  Future<PaymentModel> getOrderPayment({required String orderId});
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final DioClient dioClient;

  PaymentRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PaymentIntentResultModel> createPaymentIntent({
    required String orderId,
  }) async {
    final response = await dioClient.post('/payments/orders/$orderId/create');
    return PaymentIntentResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<PaymentProcessResultModel> processPayment({
    required String paymentId,
    bool simulateFailure = false,
  }) async {
    final response = await dioClient.post(
      '/payments/$paymentId/process',
      data: {'simulate_failure': simulateFailure},
    );
    return PaymentProcessResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<PaymentModel> getPayment({required String paymentId}) async {
    final response = await dioClient.get('/payments/$paymentId');
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PaymentModel> getOrderPayment({required String orderId}) async {
    final response = await dioClient.get('/payments/orders/$orderId');
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
