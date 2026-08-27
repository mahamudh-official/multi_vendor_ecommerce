import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/entities/payment.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/usecases/payment_usecases.dart';
import 'package:multi_vendor_ecommerce/features/payment/presentation/bloc/payment_bloc.dart';

class MockCreatePaymentUseCase extends Mock implements CreatePaymentUseCase {}

class MockProcessPaymentUseCase extends Mock implements ProcessPaymentUseCase {}

class MockGetPaymentUseCase extends Mock implements GetPaymentUseCase {}

class MockGetOrderPaymentUseCase extends Mock
    implements GetOrderPaymentUseCase {}

void main() {
  late PaymentBloc paymentBloc;
  late MockCreatePaymentUseCase mockCreatePaymentUseCase;
  late MockProcessPaymentUseCase mockProcessPaymentUseCase;
  late MockGetPaymentUseCase mockGetPaymentUseCase;
  late MockGetOrderPaymentUseCase mockGetOrderPaymentUseCase;

  const tIntent = PaymentIntentResult(
    paymentId: 'pay-1',
    orderId: 'ord-1',
    amount: 154.99,
    currency: 'USD',
    status: PaymentStatus.pending,
    provider: 'mock',
    providerPaymentId: 'mock_pi_123',
    clientSecret: 'secret_123',
  );

  final tPayment = Payment(
    id: 'pay-1',
    orderId: 'ord-1',
    userId: 'user-1',
    amount: 154.99,
    currency: 'USD',
    status: PaymentStatus.succeeded,
    provider: 'mock',
    providerPaymentId: 'mock_pi_123',
    createdAt: DateTime.parse('2026-08-28T00:00:00Z'),
    updatedAt: DateTime.parse('2026-08-28T00:00:00Z'),
  );

  final tSuccessResult = PaymentProcessResult(
    success: true,
    payment: tPayment,
    message: 'Payment processed successfully.',
    transactionId: 'mock_txn_123',
  );

  setUp(() {
    mockCreatePaymentUseCase = MockCreatePaymentUseCase();
    mockProcessPaymentUseCase = MockProcessPaymentUseCase();
    mockGetPaymentUseCase = MockGetPaymentUseCase();
    mockGetOrderPaymentUseCase = MockGetOrderPaymentUseCase();

    paymentBloc = PaymentBloc(
      createPaymentUseCase: mockCreatePaymentUseCase,
      processPaymentUseCase: mockProcessPaymentUseCase,
      getPaymentUseCase: mockGetPaymentUseCase,
      getOrderPaymentUseCase: mockGetOrderPaymentUseCase,
    );
  });

  tearDown(() {
    paymentBloc.close();
  });

  test('initial state should be PaymentInitial', () {
    expect(paymentBloc.state, const PaymentInitial());
  });

  group('PaymentIntentRequested', () {
    test(
      'emits [PaymentCreatingIntent, PaymentIntentCreatedState] on success',
      () async {
        when(
          () => mockCreatePaymentUseCase('ord-1'),
        ).thenAnswer((_) async => const Success(tIntent));

        final expected = [
          const PaymentCreatingIntent(),
          const PaymentIntentCreatedState(intent: tIntent),
        ];

        expectLater(paymentBloc.stream, emitsInOrder(expected));
        paymentBloc.add(const PaymentIntentRequested(orderId: 'ord-1'));
      },
    );

    test(
      'emits [PaymentCreatingIntent, PaymentFailureState] on failure',
      () async {
        when(() => mockCreatePaymentUseCase('ord-1')).thenAnswer(
          (_) async => const Error(ServerFailure(message: 'Order not found')),
        );

        final expected = [
          const PaymentCreatingIntent(),
          const PaymentFailureState(message: 'Order not found'),
        ];

        expectLater(paymentBloc.stream, emitsInOrder(expected));
        paymentBloc.add(const PaymentIntentRequested(orderId: 'ord-1'));
      },
    );
  });

  group('PaymentProcessRequested', () {
    test(
      'emits [PaymentProcessingState, PaymentSuccessState] on successful payment',
      () async {
        when(
          () => mockProcessPaymentUseCase(
            paymentId: 'pay-1',
            simulateFailure: false,
          ),
        ).thenAnswer((_) async => Success(tSuccessResult));

        final expected = [
          const PaymentProcessingState(),
          PaymentSuccessState(result: tSuccessResult),
        ];

        expectLater(paymentBloc.stream, emitsInOrder(expected));
        paymentBloc.add(
          const PaymentProcessRequested(
            paymentId: 'pay-1',
            simulateFailure: false,
          ),
        );
      },
    );

    test(
      'emits [PaymentProcessingState, PaymentFailureState] on simulated failure',
      () async {
        final tFailResult = PaymentProcessResult(
          success: false,
          payment: tPayment,
          message: 'Simulated card declined',
        );

        when(
          () => mockProcessPaymentUseCase(
            paymentId: 'pay-1',
            simulateFailure: true,
          ),
        ).thenAnswer((_) async => Success(tFailResult));

        final expected = [
          const PaymentProcessingState(),
          const PaymentFailureState(
            message: 'Simulated card declined',
            paymentId: 'pay-1',
          ),
        ];

        expectLater(paymentBloc.stream, emitsInOrder(expected));
        paymentBloc.add(
          const PaymentProcessRequested(
            paymentId: 'pay-1',
            simulateFailure: true,
          ),
        );
      },
    );
  });
}
