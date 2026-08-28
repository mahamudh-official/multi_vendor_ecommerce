import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/entities/seller_analytics.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/repositories/seller_analytics_repository.dart';

class GetSellerAnalyticsOverviewUseCase {
  final SellerAnalyticsRepository repository;

  GetSellerAnalyticsOverviewUseCase(this.repository);

  Future<Result<SellerAnalyticsOverview>> call() {
    return repository.getOverview();
  }
}

class GetSellerSalesAnalyticsUseCase {
  final SellerAnalyticsRepository repository;

  GetSellerSalesAnalyticsUseCase(this.repository);

  Future<Result<List<SellerSalesPeriodItem>>> call({String period = 'daily'}) {
    return repository.getSalesAnalytics(period: period);
  }
}

class GetSellerProductAnalyticsUseCase {
  final SellerAnalyticsRepository repository;

  GetSellerProductAnalyticsUseCase(this.repository);

  Future<Result<List<SellerProductAnalyticsItem>>> call({int limit = 10}) {
    return repository.getProductAnalytics(limit: limit);
  }
}
