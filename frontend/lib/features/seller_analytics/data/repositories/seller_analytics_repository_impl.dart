import 'package:dio/dio.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/data/datasources/seller_analytics_remote_datasource.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/entities/seller_analytics.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/repositories/seller_analytics_repository.dart';

class SellerAnalyticsRepositoryImpl implements SellerAnalyticsRepository {
  final SellerAnalyticsRemoteDataSource remoteDataSource;

  SellerAnalyticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<SellerAnalyticsOverview>> getOverview() async {
    try {
      final res = await remoteDataSource.getOverview();
      return Success(res);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? 'Failed to fetch analytics overview';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<SellerSalesPeriodItem>>> getSalesAnalytics({String period = 'daily'}) async {
    try {
      final res = await remoteDataSource.getSalesAnalytics(period: period);
      return Success(res);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? 'Failed to fetch sales analytics';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<SellerProductAnalyticsItem>>> getProductAnalytics({int limit = 10}) async {
    try {
      final res = await remoteDataSource.getProductAnalytics(limit: limit);
      return Success(res);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? 'Failed to fetch product analytics';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
