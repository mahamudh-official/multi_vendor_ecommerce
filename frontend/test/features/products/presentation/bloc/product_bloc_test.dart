import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/products/domain/entities/category.dart';
import 'package:multi_vendor_ecommerce/features/products/domain/entities/paginated_products.dart';
import 'package:multi_vendor_ecommerce/features/products/domain/entities/product.dart';
import 'package:multi_vendor_ecommerce/features/products/domain/entities/seller_summary.dart';
import 'package:multi_vendor_ecommerce/features/products/domain/usecases/get_products_usecase.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/product/product_event.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/product/product_state.dart';

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

void main() {
  late MockGetProductsUseCase mockGetProductsUseCase;
  late ProductBloc productBloc;

  final sampleCategory = const Category(
    id: 'cat-123',
    name: 'Electronics',
    slug: 'electronics',
  );

  final sampleSeller = const SellerSummary(
    id: 'seller-456',
    fullName: 'Tech Superstore',
  );

  final sampleProduct = Product(
    id: 'prod-789',
    name: 'Wireless Headphones',
    slug: 'wireless-headphones',
    price: 99.99,
    category: sampleCategory,
    seller: sampleSeller,
    createdAt: DateTime(2026, 1, 1),
  );

  final samplePaginated = PaginatedProducts(
    items: [sampleProduct],
    page: 1,
    pageSize: 20,
    total: 1,
    totalPages: 1,
  );

  setUp(() {
    mockGetProductsUseCase = MockGetProductsUseCase();
    productBloc = ProductBloc(getProductsUseCase: mockGetProductsUseCase);
  });

  tearDown(() {
    productBloc.close();
  });

  group('ProductBloc', () {
    test('initial state is ProductInitial', () {
      expect(productBloc.state, const ProductInitial());
    });

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductsLoaded] on successful ProductsRequested',
      build: () {
        when(
          () => mockGetProductsUseCase(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            search: any(named: 'search'),
            categoryId: any(named: 'categoryId'),
            sellerId: any(named: 'sellerId'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            isFeatured: any(named: 'isFeatured'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => Success(samplePaginated));
        return productBloc;
      },
      act: (bloc) => bloc.add(const ProductsRequested()),
      expect: () => [
        const ProductLoading(),
        ProductsLoaded(data: samplePaginated),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductFailure] on failed ProductsRequested',
      build: () {
        when(
          () => mockGetProductsUseCase(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            search: any(named: 'search'),
            categoryId: any(named: 'categoryId'),
            sellerId: any(named: 'sellerId'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            isFeatured: any(named: 'isFeatured'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => const Error(ServerFailure(message: 'Server error')),
        );
        return productBloc;
      },
      act: (bloc) => bloc.add(const ProductsRequested()),
      expect: () => [
        const ProductLoading(),
        const ProductFailure('Server error'),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductsLoaded] on ProductSearchChanged',
      build: () {
        when(
          () => mockGetProductsUseCase(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            search: 'Headphones',
            categoryId: any(named: 'categoryId'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => Success(samplePaginated));
        return productBloc;
      },
      act: (bloc) => bloc.add(const ProductSearchChanged('Headphones')),
      expect: () => [
        const ProductLoading(),
        ProductsLoaded(data: samplePaginated, search: 'Headphones'),
      ],
    );
  });
}
