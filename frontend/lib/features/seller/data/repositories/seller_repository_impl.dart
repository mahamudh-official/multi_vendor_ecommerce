import 'package:dio/dio.dart';
import 'package:multi_vendor_ecommerce/core/error/exceptions.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller/data/datasources/seller_remote_datasource.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_dashboard_stats.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_order.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_product.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/repositories/seller_repository.dart';

class SellerRepositoryImpl implements SellerRepository {
  final SellerRemoteDataSource remoteDataSource;

  const SellerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<SellerDashboard>> getDashboard() async {
    try {
      final dashboard = await remoteDataSource.getDashboard();
      return Success(dashboard);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<SellerProduct>>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    bool? isActive,
    bool? lowStock,
    String sort = 'newest',
  }) async {
    try {
      final products = await remoteDataSource.getProducts(
        page: page,
        pageSize: pageSize,
        search: search,
        categoryId: categoryId,
        isActive: isActive,
        lowStock: lowStock,
        sort: sort,
      );
      return Success(products);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<SellerProduct>> getProduct(String id) async {
    try {
      final product = await remoteDataSource.getProduct(id);
      return Success(product);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<SellerProduct>> createProduct({
    required String name,
    required double price,
    required int stockQuantity,
    required String categoryId,
    String? description,
    String? sku,
    String? imageUrl,
    bool isActive = true,
  }) async {
    try {
      final product = await remoteDataSource.createProduct(
        name: name,
        price: price,
        stockQuantity: stockQuantity,
        categoryId: categoryId,
        description: description,
        sku: sku,
        imageUrl: imageUrl,
        isActive: isActive,
      );
      return Success(product);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<SellerProduct>> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? categoryId,
    String? sku,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      final product = await remoteDataSource.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        stockQuantity: stockQuantity,
        categoryId: categoryId,
        sku: sku,
        imageUrl: imageUrl,
        isActive: isActive,
      );
      return Success(product);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deactivateProduct(String id) async {
    try {
      await remoteDataSource.deactivateProduct(id);
      return const Success(null);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<SellerOrder>>> getOrders({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final orders = await remoteDataSource.getOrders(
        status: status,
        search: search,
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
  Future<Result<SellerOrder>> getOrderDetails(String orderId) async {
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
  Future<Result<SellerOrder>> updateOrderStatus({
    required String orderId,
    required FulfillmentStatus status,
  }) async {
    try {
      final updatedOrder = await remoteDataSource.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      return Success(updatedOrder);
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
      message: detail ?? error.message ?? 'Seller request failed',
    );
  }
}
