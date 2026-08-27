import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_product.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/usecases/seller_product_usecases.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_products/seller_products_bloc.dart';

class MockGetSellerProductsUseCase extends Mock
    implements GetSellerProductsUseCase {}

class MockGetSellerProductUseCase extends Mock
    implements GetSellerProductUseCase {}

class MockCreateSellerProductUseCase extends Mock
    implements CreateSellerProductUseCase {}

class MockUpdateSellerProductUseCase extends Mock
    implements UpdateSellerProductUseCase {}

class MockDeactivateSellerProductUseCase extends Mock
    implements DeactivateSellerProductUseCase {}

void main() {
  late SellerProductsBloc bloc;
  late MockGetSellerProductsUseCase mockGetProductsUseCase;
  late MockGetSellerProductUseCase mockGetProductUseCase;
  late MockCreateSellerProductUseCase mockCreateProductUseCase;
  late MockUpdateSellerProductUseCase mockUpdateProductUseCase;
  late MockDeactivateSellerProductUseCase mockDeactivateProductUseCase;

  final tProduct = SellerProduct(
    id: 'prod-1',
    sellerId: 'seller-1',
    categoryId: 'cat-1',
    name: 'Wireless Mouse',
    slug: 'wireless-mouse',
    price: 49.99,
    stockQuantity: 12,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockGetProductsUseCase = MockGetSellerProductsUseCase();
    mockGetProductUseCase = MockGetSellerProductUseCase();
    mockCreateProductUseCase = MockCreateSellerProductUseCase();
    mockUpdateProductUseCase = MockUpdateSellerProductUseCase();
    mockDeactivateProductUseCase = MockDeactivateSellerProductUseCase();

    bloc = SellerProductsBloc(
      getProductsUseCase: mockGetProductsUseCase,
      getProductUseCase: mockGetProductUseCase,
      createProductUseCase: mockCreateProductUseCase,
      updateProductUseCase: mockUpdateProductUseCase,
      deactivateProductUseCase: mockDeactivateProductUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be SellerProductsInitial', () {
    expect(bloc.state, const SellerProductsInitial());
  });

  test('SellerProductsRequested emits [Loading, Loaded] on success', () async {
    when(
      () => mockGetProductsUseCase(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        categoryId: any(named: 'categoryId'),
        isActive: any(named: 'isActive'),
        lowStock: any(named: 'lowStock'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => Success([tProduct]));

    expectLater(
      bloc.stream,
      emitsInOrder([
        const SellerProductsLoading(),
        SellerProductsLoaded(products: [tProduct]),
      ]),
    );

    bloc.add(const SellerProductsRequested());
  });

  test(
    'SellerProductCreated emits [ActionLoading, ActionSuccess] on success',
    () async {
      when(
        () => mockCreateProductUseCase(
          name: any(named: 'name'),
          price: any(named: 'price'),
          stockQuantity: any(named: 'stockQuantity'),
          categoryId: any(named: 'categoryId'),
          description: any(named: 'description'),
          sku: any(named: 'sku'),
          imageUrl: any(named: 'imageUrl'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => Success(tProduct));

      expectLater(
        bloc.stream,
        emitsInOrder([
          const SellerProductActionLoading(),
          SellerProductActionSuccess(
            message: 'Product created successfully!',
            product: tProduct,
          ),
        ]),
      );

      bloc.add(
        const SellerProductCreated(
          name: 'Wireless Mouse',
          price: 49.99,
          stockQuantity: 12,
          categoryId: 'cat-1',
        ),
      );
    },
  );

  test(
    'SellerProductDeactivated emits [ActionLoading, ActionSuccess] on success',
    () async {
      when(
        () => mockDeactivateProductUseCase(any()),
      ).thenAnswer((_) async => const Success(null));

      expectLater(
        bloc.stream,
        emitsInOrder([
          const SellerProductActionLoading(),
          const SellerProductActionSuccess(
            message: 'Product deactivated successfully.',
          ),
        ]),
      );

      bloc.add(const SellerProductDeactivated(productId: 'prod-1'));
    },
  );

  test('SellerProductsReset emits SellerProductsInitial', () async {
    expectLater(bloc.stream, emitsInOrder([const SellerProductsInitial()]));

    bloc.add(const SellerProductsReset());
  });
}
