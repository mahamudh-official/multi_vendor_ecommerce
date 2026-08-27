import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/products/domain/entities/category.dart';
import 'package:multi_vendor_ecommerce/features/products/domain/usecases/get_categories_usecase.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_bloc.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_event.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_state.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

void main() {
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late CategoryBloc categoryBloc;

  final sampleCategories = [
    const Category(id: 'cat-1', name: 'Electronics', slug: 'electronics'),
    const Category(id: 'cat-2', name: 'Fashion', slug: 'fashion'),
  ];

  setUp(() {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    categoryBloc = CategoryBloc(getCategoriesUseCase: mockGetCategoriesUseCase);
  });

  tearDown(() {
    categoryBloc.close();
  });

  group('CategoryBloc', () {
    test('initial state is CategoryInitial', () {
      expect(categoryBloc.state, const CategoryInitial());
    });

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryLoading, CategoryLoaded] on successful CategoriesRequested',
      build: () {
        when(
          () => mockGetCategoriesUseCase(),
        ).thenAnswer((_) async => Success(sampleCategories));
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const CategoriesRequested()),
      expect: () => [
        const CategoryLoading(),
        CategoryLoaded(categories: sampleCategories),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryLoading, CategoryFailure] on failed CategoriesRequested',
      build: () {
        when(() => mockGetCategoriesUseCase()).thenAnswer(
          (_) async =>
              const Error(ServerFailure(message: 'Failed to load categories')),
        );
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const CategoriesRequested()),
      expect: () => [
        const CategoryLoading(),
        const CategoryFailure('Failed to load categories'),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits updated CategoryLoaded when CategorySelected is dispatched',
      build: () => categoryBloc,
      seed: () => CategoryLoaded(categories: sampleCategories),
      act: (bloc) => bloc.add(const CategorySelected('cat-1')),
      expect: () => [
        CategoryLoaded(
          categories: sampleCategories,
          selectedCategoryId: 'cat-1',
        ),
      ],
    );
  });
}
