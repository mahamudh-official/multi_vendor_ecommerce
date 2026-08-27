import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/shipping_address.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl({required this.remoteDataSource});

  final OrderRemoteDataSource remoteDataSource;

  @override
  Future<Result<Order>> checkout({
    required ShippingAddress shippingAddress,
    String? customerNote,
    String? idempotencyKey,
  }) async {
    try {
      final order = await remoteDataSource.checkout(
        shippingAddress: shippingAddress,
        customerNote: customerNote,
        idempotencyKey: idempotencyKey,
      );
      return Success(order);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Order>>> getOrders({
    OrderStatus? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final orders = await remoteDataSource.getOrders(
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return Success(orders);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Order>> getOrderDetails(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderDetails(orderId);
      return Success(order);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> cancelOrder(String orderId) async {
    try {
      await remoteDataSource.cancelOrder(orderId);
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
      message: detail ?? error.message ?? 'Order request failed',
    );
  }
}
