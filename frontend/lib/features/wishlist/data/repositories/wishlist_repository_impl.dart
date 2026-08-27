import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  const WishlistRepositoryImpl({required this.remoteDataSource});

  final WishlistRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<WishlistItem>>> getWishlist() async {
    try {
      final items = await remoteDataSource.getWishlist();
      return Success(items);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<WishlistItem>> addToWishlist(String productId) async {
    try {
      final item = await remoteDataSource.addToWishlist(productId);
      return Success(item);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> removeFromWishlist(String productId) async {
    try {
      await remoteDataSource.removeFromWishlist(productId);
      return const Success(null);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> clearWishlist() async {
    try {
      await remoteDataSource.clearWishlist();
      return const Success(null);
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
      message: detail ?? error.message ?? 'Wishlist request failed',
    );
  }
}
