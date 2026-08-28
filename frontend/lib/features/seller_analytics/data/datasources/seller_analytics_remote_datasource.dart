import 'package:multi_vendor_ecommerce/core/network/dio_client.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/data/models/seller_analytics_models.dart';

abstract class SellerAnalyticsRemoteDataSource {
  Future<SellerAnalyticsOverviewModel> getOverview();
  Future<List<SellerSalesPeriodItemModel>> getSalesAnalytics({
    String period = 'daily',
  });
  Future<List<SellerProductAnalyticsItemModel>> getProductAnalytics({
    int limit = 10,
  });
}

class SellerAnalyticsRemoteDataSourceImpl
    implements SellerAnalyticsRemoteDataSource {
  final DioClient dioClient;

  SellerAnalyticsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<SellerAnalyticsOverviewModel> getOverview() async {
    final response = await dioClient.get<Map<String, dynamic>>(
      '/seller/analytics/overview',
    );
    return SellerAnalyticsOverviewModel.fromJson(response.data!);
  }

  @override
  Future<List<SellerSalesPeriodItemModel>> getSalesAnalytics({
    String period = 'daily',
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      '/seller/analytics/sales',
      queryParameters: {'period': period},
    );
    final items = response.data!['items'] as List<dynamic>;
    return items
        .map(
          (e) => SellerSalesPeriodItemModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<SellerProductAnalyticsItemModel>> getProductAnalytics({
    int limit = 10,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      '/seller/analytics/products',
      queryParameters: {'limit': limit},
    );
    final items = response.data!['items'] as List<dynamic>;
    return items
        .map(
          (e) => SellerProductAnalyticsItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
