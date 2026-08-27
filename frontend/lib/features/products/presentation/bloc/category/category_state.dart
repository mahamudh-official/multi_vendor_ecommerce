import 'package:equatable/equatable.dart';
import '../../../domain/entities/category.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

final class CategoryLoaded extends CategoryState {
  const CategoryLoaded({required this.categories, this.selectedCategoryId});

  final List<Category> categories;
  final String? selectedCategoryId;

  CategoryLoaded copyWith({
    List<Category>? categories,
    String? Function()? selectedCategoryId,
  }) {
    return CategoryLoaded(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId != null
          ? selectedCategoryId()
          : this.selectedCategoryId,
    );
  }

  @override
  List<Object?> get props => [categories, selectedCategoryId];
}

final class CategoryFailure extends CategoryState {
  const CategoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
