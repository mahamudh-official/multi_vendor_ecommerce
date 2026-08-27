import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/cart/domain/entities/cart_product.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/domain/usecases/clear_wishlist_usecase.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/domain/usecases/get_wishlist_usecase.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/presentation/bloc/wishlist_event.dart';
import 'package:multi_vendor_ecommerce/features/wishlist/presentation/bloc/wishlist_state.dart';

class MockGetWishlistUseCase extends Mock implements GetWishlistUseCase {}

class MockAddToWishlistUseCase extends Mock implements AddToWishlistUseCase {}

class MockRemoveFromWishlistUseCase extends Mock
    implements RemoveFromWishlistUseCase {}

class MockClearWishlistUseCase extends Mock implements ClearWishlistUseCase {}

void main() {
  late WishlistBloc wishlistBloc;
  late MockGetWishlistUseCase mockGetWishlistUseCase;
  late MockAddToWishlistUseCase mockAddToWishlistUseCase;
  late MockRemoveFromWishlistUseCase mockRemoveFromWishlistUseCase;
  late MockClearWishlistUseCase mockClearWishlistUseCase;

  const tProduct = CartProduct(
    id: 'prod-1',
    name: 'Wireless Mouse',
    slug: 'wireless-mouse',
    price: 49.99,
  );

  final tWishlistItem = WishlistItem(
    id: 'w-1',
    product: tProduct,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockGetWishlistUseCase = MockGetWishlistUseCase();
    mockAddToWishlistUseCase = MockAddToWishlistUseCase();
    mockRemoveFromWishlistUseCase = MockRemoveFromWishlistUseCase();
    mockClearWishlistUseCase = MockClearWishlistUseCase();

    wishlistBloc = WishlistBloc(
      getWishlistUseCase: mockGetWishlistUseCase,
      addToWishlistUseCase: mockAddToWishlistUseCase,
      removeFromWishlistUseCase: mockRemoveFromWishlistUseCase,
      clearWishlistUseCase: mockClearWishlistUseCase,
    );
  });

  tearDown(() => wishlistBloc.close());

  test('WishlistBloc initial state is WishlistInitial', () {
    expect(wishlistBloc.state, const WishlistInitial());
  });

  test(
    'WishlistBloc emits [WishlistLoading, WishlistLoaded] on successful WishlistRequested',
    () async {
      when(
        () => mockGetWishlistUseCase(),
      ).thenAnswer((_) async => Success([tWishlistItem]));

      expectLater(
        wishlistBloc.stream,
        emitsInOrder([
          const WishlistLoading(),
          WishlistLoaded(items: [tWishlistItem]),
        ]),
      );

      wishlistBloc.add(const WishlistRequested());
    },
  );

  test(
    'WishlistBloc emits [WishlistLoading, WishlistFailure] on failed WishlistRequested',
    () async {
      when(() => mockGetWishlistUseCase()).thenAnswer(
        (_) async =>
            const Error(ServerFailure(message: 'Failed to load wishlist')),
      );

      expectLater(
        wishlistBloc.stream,
        emitsInOrder([
          const WishlistLoading(),
          const WishlistFailure('Failed to load wishlist'),
        ]),
      );

      wishlistBloc.add(const WishlistRequested());
    },
  );

  test('WishlistBloc emits WishlistInitial on WishlistReset', () async {
    wishlistBloc.add(const WishlistReset());
    expectLater(wishlistBloc.stream, emits(const WishlistInitial()));
  });
}
