import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/entities/order_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_order.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/usecases/seller_order_usecases.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_orders/seller_orders_bloc.dart';

class MockGetSellerOrdersUseCase extends Mock
    implements GetSellerOrdersUseCase {}

class MockGetSellerOrderDetailsUseCase extends Mock
    implements GetSellerOrderDetailsUseCase {}

class MockUpdateSellerOrderStatusUseCase extends Mock
    implements UpdateSellerOrderStatusUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(FulfillmentStatus.pending);
  });

  late SellerOrdersBloc bloc;
  late MockGetSellerOrdersUseCase mockGetOrdersUseCase;
  late MockGetSellerOrderDetailsUseCase mockGetOrderDetailsUseCase;
  late MockUpdateSellerOrderStatusUseCase mockUpdateOrderStatusUseCase;

  final tOrder = SellerOrder(
    id: 'order-1',
    orderNumber: 'ORD-20260828-ABCDEF',
    status: OrderStatus.pending,
    paymentStatus: 'pending',
    sellerItemCount: 2,
    sellerSubtotal: 199.98,
    customerName: 'Alice Buyer',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockGetOrdersUseCase = MockGetSellerOrdersUseCase();
    mockGetOrderDetailsUseCase = MockGetSellerOrderDetailsUseCase();
    mockUpdateOrderStatusUseCase = MockUpdateSellerOrderStatusUseCase();

    bloc = SellerOrdersBloc(
      getOrdersUseCase: mockGetOrdersUseCase,
      getOrderDetailsUseCase: mockGetOrderDetailsUseCase,
      updateOrderStatusUseCase: mockUpdateOrderStatusUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be SellerOrdersInitial', () {
    expect(bloc.state, const SellerOrdersInitial());
  });

  test('SellerOrdersRequested emits [Loading, Loaded] on success', () async {
    when(
      () => mockGetOrdersUseCase(
        status: any(named: 'status'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Success([tOrder]));

    expectLater(
      bloc.stream,
      emitsInOrder([
        const SellerOrdersLoading(),
        SellerOrdersLoaded(orders: [tOrder]),
      ]),
    );

    bloc.add(const SellerOrdersRequested());
  });

  test(
    'SellerOrderDetailsRequested emits [Loading, DetailsLoaded] on success',
    () async {
      when(
        () => mockGetOrderDetailsUseCase(any()),
      ).thenAnswer((_) async => Success(tOrder));

      expectLater(
        bloc.stream,
        emitsInOrder([
          const SellerOrdersLoading(),
          SellerOrderDetailsLoaded(order: tOrder),
        ]),
      );

      bloc.add(const SellerOrderDetailsRequested(orderId: 'order-1'));
    },
  );

  test(
    'SellerOrderStatusUpdated emits [Updating, UpdateSuccess, DetailsLoaded] on success',
    () async {
      when(
        () => mockUpdateOrderStatusUseCase(
          orderId: any(named: 'orderId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => Success(tOrder));

      expectLater(
        bloc.stream,
        emitsInOrder([
          const SellerOrderStatusUpdating(),
          SellerOrderStatusUpdateSuccess(
            message: 'Status updated to Confirmed',
            updatedOrder: tOrder,
          ),
          SellerOrderDetailsLoaded(order: tOrder),
        ]),
      );

      bloc.add(
        const SellerOrderStatusUpdated(
          orderId: 'order-1',
          status: FulfillmentStatus.confirmed,
        ),
      );
    },
  );

  test('SellerOrdersReset emits SellerOrdersInitial', () async {
    expectLater(bloc.stream, emitsInOrder([const SellerOrdersInitial()]));

    bloc.add(const SellerOrdersReset());
  });
}
