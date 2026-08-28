import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/entities/seller_analytics.dart';

abstract class SellerAnalyticsRepository {
  Future<Result<SellerAnalyticsOverview>> getOverview();
  Future<Result<List<SellerSalesPeriodItem>>> getSalesAnalytics({
    String period = 'daily',
  });
  Future<Result<List<SellerProductAnalyticsItem>>> getProductAnalytics({
    int limit = 10,
  });
}
