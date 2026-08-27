import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/entities/order.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/entities/order_item.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/entities/order_status.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/entities/shipping_address.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/usecases/checkout_usecase.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/usecases/get_order_details_usecase.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:multi_vendor_ecommerce/features/orders/presentation/bloc/order_bloc.dart';
import 'package:multi_vendor_ecommerce/features/orders/presentation/bloc/order_event.dart';
import 'package:multi_vendor_ecommerce/features/orders/presentation/bloc/order_state.dart';

class MockCheckoutUseCase extends Mock implements CheckoutUseCase {}

class MockGetOrdersUseCase extends Mock implements GetOrdersUseCase {}

class MockGetOrderDetailsUseCase extends Mock
    implements GetOrderDetailsUseCase {}

class MockCancelOrderUseCase extends Mock implements CancelOrderUseCase {}

class FakeShippingAddress extends Fake implements ShippingAddress {}

void main() {
  late OrderBloc orderBloc;
  late MockCheckoutUseCase mockCheckoutUseCase;
  late MockGetOrdersUseCase mockGetOrdersUseCase;
  late MockGetOrderDetailsUseCase mockGetOrderDetailsUseCase;
  late MockCancelOrderUseCase mockCancelOrderUseCase;

  const tShipping = ShippingAddress(
    fullName: 'Jane Doe',
    phone: '+1-555-0199',
    addressLine1: '123 Market Street',
    city: 'San Francisco',
    state: 'CA',
    postalCode: '94103',
    country: 'USA',
  );

  final tOrderItem = OrderItem(
    id: 'item-1',
    productId: 'prod-1',
    sellerId: 'seller-1',
    productName: 'Mechanical Keyboard',
    productSku: 'KEY-001',
    unitPrice: 149.99,
    quantity: 1,
    lineTotal: 149.99,
    createdAt: DateTime.parse('2026-08-28T00:00:00Z'),
  );

  final tOrder = Order(
    id: 'ord-1',
    userId: 'user-1',
    orderNumber: 'ORD-20260828-ABC123',
    status: OrderStatus.pending,
    paymentStatus: 'pending',
    subtotal: 149.99,
    shippingFee: 0.0,
    discountAmount: 0.0,
    taxAmount: 0.0,
    totalAmount: 149.99,
    currency: 'USD',
    shippingAddress: tShipping,
    items: [tOrderItem],
    itemCount: 1,
    createdAt: DateTime.parse('2026-08-28T00:00:00Z'),
    updatedAt: DateTime.parse('2026-08-28T00:00:00Z'),
  );

  setUpAll(() {
    registerFallbackValue(FakeShippingAddress());
  });

  setUp(() {
    mockCheckoutUseCase = MockCheckoutUseCase();
    mockGetOrdersUseCase = MockGetOrdersUseCase();
    mockGetOrderDetailsUseCase = MockGetOrderDetailsUseCase();
    mockCancelOrderUseCase = MockCancelOrderUseCase();

    orderBloc = OrderBloc(
      checkoutUseCase: mockCheckoutUseCase,
      getOrdersUseCase: mockGetOrdersUseCase,
      getOrderDetailsUseCase: mockGetOrderDetailsUseCase,
      cancelOrderUseCase: mockCancelOrderUseCase,
    );
  });

  tearDown(() {
    orderBloc.close();
  });

  test('initial state should be OrderInitial', () {
    expect(orderBloc.state, const OrderInitial());
  });

  group('CheckoutSubmitted', () {
    test(
      'emits [CheckoutLoading, CheckoutSuccess] on successful checkout',
      () async {
        when(
          () => mockCheckoutUseCase(
            shippingAddress: any(named: 'shippingAddress'),
            customerNote: any(named: 'customerNote'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer((_) async => Success(tOrder));

        final expected = [const CheckoutLoading(), CheckoutSuccess(tOrder)];

        expectLater(orderBloc.stream, emitsInOrder(expected));

        orderBloc.add(const CheckoutSubmitted(shippingAddress: tShipping));
      },
    );

    test('emits [CheckoutLoading, OrderFailure] on checkout failure', () async {
      when(
        () => mockCheckoutUseCase(
          shippingAddress: any(named: 'shippingAddress'),
          customerNote: any(named: 'customerNote'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer(
        (_) async => const Error(ServerFailure(message: 'Cart is empty')),
      );

      final expected = [
        const CheckoutLoading(),
        const OrderFailure('Cart is empty'),
      ];

      expectLater(orderBloc.stream, emitsInOrder(expected));

      orderBloc.add(const CheckoutSubmitted(shippingAddress: tShipping));
    });
  });

  group('OrdersRequested', () {
    test('emits [OrderLoading, OrdersLoaded] on success', () async {
      when(
        () => mockGetOrdersUseCase(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Success([tOrder]));

      final expected = [
        const OrderLoading(),
        OrdersLoaded(orders: [tOrder]),
      ];

      expectLater(orderBloc.stream, emitsInOrder(expected));

      orderBloc.add(const OrdersRequested());
    });

    test('emits [OrderLoading, OrderFailure] on failure', () async {
      when(
        () => mockGetOrdersUseCase(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => const Error(ServerFailure(message: 'Failed to fetch')),
      );

      final expected = [
        const OrderLoading(),
        const OrderFailure('Failed to fetch'),
      ];

      expectLater(orderBloc.stream, emitsInOrder(expected));

      orderBloc.add(const OrdersRequested());
    });
  });

  group('OrderDetailsRequested', () {
    test('emits [OrderLoading, OrderDetailsLoaded] on success', () async {
      when(
        () => mockGetOrderDetailsUseCase('ord-1'),
      ).thenAnswer((_) async => Success(tOrder));

      final expected = [
        const OrderLoading(),
        OrderDetailsLoaded(order: tOrder),
      ];

      expectLater(orderBloc.stream, emitsInOrder(expected));

      orderBloc.add(const OrderDetailsRequested('ord-1'));
    });
  });

  test('OrdersReset emits OrderInitial', () async {
    final expected = [const OrderInitial()];

    expectLater(orderBloc.stream, emitsInOrder(expected));

    orderBloc.add(const OrdersReset());
  });
}
