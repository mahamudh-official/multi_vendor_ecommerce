import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl({required this.remoteDataSource});

  final CartRemoteDataSource remoteDataSource;

  @override
  Future<Result<Cart>> getCart() async {
    try {
      final cart = await remoteDataSource.getCart();
      return Success(cart);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Cart>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final cart = await remoteDataSource.addToCart(
        productId: productId,
        quantity: quantity,
      );
      return Success(cart);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Cart>> updateCartItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final cart = await remoteDataSource.updateCartItemQuantity(
        itemId: itemId,
        quantity: quantity,
      );
      return Success(cart);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Cart>> removeCartItem({required String itemId}) async {
    try {
      final cart = await remoteDataSource.removeCartItem(itemId: itemId);
      return Success(cart);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Cart>> clearCart() async {
    try {
      final cart = await remoteDataSource.clearCart();
      return Success(cart);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  Failure _mapDioError(DioException error) {
    if (error.error is AppException) {
      final appEx = error.error as AppException;
      return ServerFailure(message: appEx.message, code: appEx.code);
    }
    final detail = error.response?.data is Map<String, dynamic>
        ? (error.response?.data as Map<String, dynamic>)['detail']?.toString()
        : null;
    return ServerFailure(
      message: detail ?? error.message ?? 'Cart request failed',
    );
  }
}
