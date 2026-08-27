import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

sealed class SellerProductState extends Equatable {
  const SellerProductState();

  @override
  List<Object?> get props => [];
}

final class SellerProductInitial extends SellerProductState {
  const SellerProductInitial();
}

final class SellerProductLoading extends SellerProductState {
  const SellerProductLoading();
}

final class SellerProductsLoaded extends SellerProductState {
  const SellerProductsLoaded(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

final class SellerProductActionSuccess extends SellerProductState {
  const SellerProductActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class SellerProductFailure extends SellerProductState {
  const SellerProductFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
