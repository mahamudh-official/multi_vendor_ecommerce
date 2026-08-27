import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_categories_usecase.dart';
import 'category_event.dart';
import 'category_state.dart';

/// BLoC managing category state and active selection.
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({required this.getCategoriesUseCase})
    : super(const CategoryInitial()) {
    on<CategoriesRequested>(_onCategoriesRequested);
    on<CategorySelected>(_onCategorySelected);
  }

  final GetCategoriesUseCase getCategoriesUseCase;

  Future<void> _onCategoriesRequested(
    CategoriesRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    final result = await getCategoriesUseCase();
    result.fold(
      onSuccess: (categories) => emit(CategoryLoaded(categories: categories)),
      onError: (failure) => emit(CategoryFailure(failure.message)),
    );
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<CategoryState> emit,
  ) {
    if (state is CategoryLoaded) {
      final current = state as CategoryLoaded;
      emit(current.copyWith(selectedCategoryId: () => event.categoryId));
    }
  }
}
