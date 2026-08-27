import 'package:equatable/equatable.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

final class CategoriesRequested extends CategoryEvent {
  const CategoriesRequested();
}

final class CategorySelected extends CategoryEvent {
  const CategorySelected(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}
