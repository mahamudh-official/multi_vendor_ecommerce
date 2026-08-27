import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/entities/payment.dart';
import 'package:multi_vendor_ecommerce/features/payment/domain/usecases/payment_usecases.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class PaymentIntentRequested extends PaymentEvent {
  final String orderId;

  const PaymentIntentRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class PaymentProcessRequested extends PaymentEvent {
  final String paymentId;
  final bool simulateFailure;

  const PaymentProcessRequested({
    required this.paymentId,
    this.simulateFailure = false,
  });

  @override
  List<Object?> get props => [paymentId, simulateFailure];
}

class PaymentReset extends PaymentEvent {
  const PaymentReset();
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentCreatingIntent extends PaymentState {
  const PaymentCreatingIntent();
}

class PaymentIntentCreatedState extends PaymentState {
  final PaymentIntentResult intent;

  const PaymentIntentCreatedState({required this.intent});

  @override
  List<Object?> get props => [intent];
}

class PaymentProcessingState extends PaymentState {
  const PaymentProcessingState();
}

class PaymentSuccessState extends PaymentState {
  final PaymentProcessResult result;

  const PaymentSuccessState({required this.result});

  @override
  List<Object?> get props => [result];
}

class PaymentFailureState extends PaymentState {
  final String message;
  final String? paymentId;

  const PaymentFailureState({required this.message, this.paymentId});

  @override
  List<Object?> get props => [message, paymentId];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePaymentUseCase createPaymentUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;
  final GetPaymentUseCase getPaymentUseCase;
  final GetOrderPaymentUseCase getOrderPaymentUseCase;

  PaymentBloc({
    required this.createPaymentUseCase,
    required this.processPaymentUseCase,
    required this.getPaymentUseCase,
    required this.getOrderPaymentUseCase,
  }) : super(const PaymentInitial()) {
    on<PaymentIntentRequested>(_onPaymentIntentRequested);
    on<PaymentProcessRequested>(_onPaymentProcessRequested);
    on<PaymentReset>(_onPaymentReset);
  }

  Future<void> _onPaymentIntentRequested(
    PaymentIntentRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentCreatingIntent());
    final result = await createPaymentUseCase(event.orderId);
    result.fold(
      onSuccess: (intent) => emit(PaymentIntentCreatedState(intent: intent)),
      onError: (failure) => emit(PaymentFailureState(message: failure.message)),
    );
  }

  Future<void> _onPaymentProcessRequested(
    PaymentProcessRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentProcessingState());
    final result = await processPaymentUseCase(
      paymentId: event.paymentId,
      simulateFailure: event.simulateFailure,
    );
    result.fold(
      onSuccess: (processResult) {
        if (processResult.success) {
          emit(PaymentSuccessState(result: processResult));
        } else {
          emit(
            PaymentFailureState(
              message: processResult.message,
              paymentId: event.paymentId,
            ),
          );
        }
      },
      onError: (failure) => emit(
        PaymentFailureState(
          message: failure.message,
          paymentId: event.paymentId,
        ),
      ),
    );
  }

  void _onPaymentReset(PaymentReset event, Emitter<PaymentState> emit) {
    emit(const PaymentInitial());
  }
}
