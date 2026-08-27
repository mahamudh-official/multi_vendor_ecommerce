import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/entities/cart.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/entities/cart_item.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/entities/cart_product.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/usecases/remove_cart_item_usecase.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/usecases/update_cart_item_usecase.dart';
import 'package:multi_vendor_ecommerce/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:multi_vendor_ecommerce/features/cart/presentation/bloc/cart_event.dart';
import 'package:multi_vendor_ecommerce/features/cart/presentation/bloc/cart_state.dart';

class MockGetCartUseCase extends Mock implements GetCartUseCase {}

class MockAddToCartUseCase extends Mock implements AddToCartUseCase {}

class MockUpdateCartItemUseCase extends Mock implements UpdateCartItemUseCase {}

class MockRemoveCartItemUseCase extends Mock implements RemoveCartItemUseCase {}

class MockClearCartUseCase extends Mock implements ClearCartUseCase {}

void main() {
  late CartBloc cartBloc;
  late MockGetCartUseCase mockGetCartUseCase;
  late MockAddToCartUseCase mockAddToCartUseCase;
  late MockUpdateCartItemUseCase mockUpdateCartItemUseCase;
  late MockRemoveCartItemUseCase mockRemoveCartItemUseCase;
  late MockClearCartUseCase mockClearCartUseCase;

  const tProduct = CartProduct(
    id: 'prod-1',
    name: 'Wireless Mouse',
    slug: 'wireless-mouse',
    price: 49.99,
    stockQuantity: 10,
    isActive: true,
  );

  const tCartItem = CartItem(
    id: 'item-1',
    product: tProduct,
    quantity: 2,
    lineTotal: 99.98,
  );

  const tCart = Cart(
    id: 'cart-1',
    items: [tCartItem],
    itemCount: 2,
    subtotal: 99.98,
  );

  setUp(() {
    mockGetCartUseCase = MockGetCartUseCase();
    mockAddToCartUseCase = MockAddToCartUseCase();
    mockUpdateCartItemUseCase = MockUpdateCartItemUseCase();
    mockRemoveCartItemUseCase = MockRemoveCartItemUseCase();
    mockClearCartUseCase = MockClearCartUseCase();

    cartBloc = CartBloc(
      getCartUseCase: mockGetCartUseCase,
      addToCartUseCase: mockAddToCartUseCase,
      updateCartItemUseCase: mockUpdateCartItemUseCase,
      removeCartItemUseCase: mockRemoveCartItemUseCase,
      clearCartUseCase: mockClearCartUseCase,
    );
  });

  tearDown(() => cartBloc.close());

  test('CartBloc initial state is CartInitial', () {
    expect(cartBloc.state, const CartInitial());
  });

  test(
    'CartBloc emits [CartLoading, CartLoaded] on successful CartRequested',
    () async {
      when(
        () => mockGetCartUseCase(),
      ).thenAnswer((_) async => const Success(tCart));

      expectLater(
        cartBloc.stream,
        emitsInOrder([const CartLoading(), const CartLoaded(cart: tCart)]),
      );

      cartBloc.add(const CartRequested());
    },
  );

  test(
    'CartBloc emits [CartLoading, CartFailure] on failed CartRequested',
    () async {
      when(() => mockGetCartUseCase()).thenAnswer(
        (_) async =>
            const Error(ServerFailure(message: 'Failed to fetch cart')),
      );

      expectLater(
        cartBloc.stream,
        emitsInOrder([
          const CartLoading(),
          const CartFailure('Failed to fetch cart'),
        ]),
      );

      cartBloc.add(const CartRequested());
    },
  );

  test(
    'CartBloc emits CartLoaded with confirmation message on AddToCart',
    () async {
      when(
        () => mockAddToCartUseCase(productId: 'prod-1', quantity: 1),
      ).thenAnswer((_) async => const Success(tCart));

      expectLater(
        cartBloc.stream,
        emitsInOrder([
          const CartLoaded(cart: tCart, message: 'Item added to cart!'),
        ]),
      );

      cartBloc.add(const AddToCart(productId: 'prod-1', quantity: 1));
    },
  );

  test('CartBloc emits CartInitial on CartReset', () async {
    cartBloc.add(const CartReset());
    expectLater(cartBloc.stream, emits(const CartInitial()));
  });
}
