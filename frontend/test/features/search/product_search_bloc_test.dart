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
import 'package:multi_vendor_ecommerce/features/search/domain/entities/search_filter_params.dart';
import 'package:multi_vendor_ecommerce/features/search/presentation/bloc/product_search_bloc.dart';
import 'package:multi_vendor_ecommerce/features/search/presentation/bloc/product_search_event.dart';
import 'package:multi_vendor_ecommerce/features/search/presentation/bloc/product_search_state.dart';

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

void main() {
  late MockGetProductsUseCase mockGetProductsUseCase;
  late ProductSearchBloc productSearchBloc;

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
    averageRating: 4.8,
    reviewCount: 12,
    createdAt: DateTime(2026, 1, 1),
  );

  final samplePaginated = PaginatedProducts(
    items: [sampleProduct],
    page: 1,
    pageSize: 20,
    total: 1,
    totalPages: 1,
    hasNext: false,
    hasPrevious: false,
  );

  setUp(() {
    mockGetProductsUseCase = MockGetProductsUseCase();
    productSearchBloc = ProductSearchBloc(
      getProductsUseCase: mockGetProductsUseCase,
    );
  });

  tearDown(() {
    productSearchBloc.close();
  });

  group('ProductSearchBloc', () {
    test(
      'initial state has ProductSearchStatus.initial and default params',
      () {
        expect(productSearchBloc.state.status, ProductSearchStatus.initial);
        expect(productSearchBloc.state.products, isEmpty);
        expect(productSearchBloc.state.params, const SearchFilterParams());
      },
    );

    blocTest<ProductSearchBloc, ProductSearchState>(
      'emits [loading, loaded] when ProductSearchFilterApplied is added',
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
            minRating: any(named: 'minRating'),
            inStock: any(named: 'inStock'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => Success(samplePaginated));
        return productSearchBloc;
      },
      act: (bloc) => bloc.add(
        const ProductSearchFilterApplied(
          categoryId: 'cat-123',
          minPrice: 50.0,
          maxPrice: 200.0,
          minRating: 4.0,
          inStockOnly: true,
          sort: 'price_low',
        ),
      ),
      expect: () => [
        isA<ProductSearchState>()
            .having((s) => s.status, 'status', ProductSearchStatus.loading)
            .having((s) => s.params.categoryId, 'categoryId', 'cat-123')
            .having((s) => s.params.minPrice, 'minPrice', 50.0)
            .having((s) => s.params.sort, 'sort', 'price_low'),
        isA<ProductSearchState>()
            .having((s) => s.status, 'status', ProductSearchStatus.loaded)
            .having((s) => s.products.length, 'products.length', 1)
            .having(
              (s) => s.products.first.name,
              'first product',
              'Wireless Headphones',
            ),
      ],
    );

    blocTest<ProductSearchBloc, ProductSearchState>(
      'emits [loading, empty] when search returns empty results',
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
            minRating: any(named: 'minRating'),
            inStock: any(named: 'inStock'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => const Success(
            PaginatedProducts(
              items: [],
              page: 1,
              pageSize: 20,
              total: 0,
              totalPages: 0,
            ),
          ),
        );
        return productSearchBloc;
      },
      act: (bloc) => bloc.add(const ProductSearchSortChanged('price_high')),
      expect: () => [
        isA<ProductSearchState>().having(
          (s) => s.status,
          'status',
          ProductSearchStatus.loading,
        ),
        isA<ProductSearchState>()
            .having((s) => s.status, 'status', ProductSearchStatus.empty)
            .having((s) => s.products, 'products', isEmpty),
      ],
    );

    blocTest<ProductSearchBloc, ProductSearchState>(
      'emits [loading, error] on server failure',
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
            minRating: any(named: 'minRating'),
            inStock: any(named: 'inStock'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => const Error(ServerFailure(message: 'Server error')),
        );
        return productSearchBloc;
      },
      act: (bloc) => bloc.add(const ProductSearchResetFilters()),
      expect: () => [
        isA<ProductSearchState>().having(
          (s) => s.status,
          'status',
          ProductSearchStatus.loading,
        ),
        isA<ProductSearchState>()
            .having((s) => s.status, 'status', ProductSearchStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', 'Server error'),
      ],
    );
  });
}
