import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/entities/seller_analytics.dart';

class SellerAnalyticsOverviewModel extends SellerAnalyticsOverview {
  const SellerAnalyticsOverviewModel({
    required super.totalRevenue,
    required super.totalOrders,
    required super.totalItemsSold,
    required super.averageOrderValue,
    required super.activeProducts,
    required super.lowStockProducts,
    required super.pendingFulfillmentCount,
    required super.deliveredOrderCount,
  });

  factory SellerAnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    return SellerAnalyticsOverviewModel(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      totalItemsSold: json['total_items_sold'] as int? ?? 0,
      averageOrderValue:
          (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
      activeProducts: json['active_products'] as int? ?? 0,
      lowStockProducts: json['low_stock_products'] as int? ?? 0,
      pendingFulfillmentCount: json['pending_fulfillment_count'] as int? ?? 0,
      deliveredOrderCount: json['delivered_order_count'] as int? ?? 0,
    );
  }
}

class SellerSalesPeriodItemModel extends SellerSalesPeriodItem {
  const SellerSalesPeriodItemModel({
    required super.period,
    required super.orderCount,
    required super.itemQuantity,
    required super.revenue,
  });

  factory SellerSalesPeriodItemModel.fromJson(Map<String, dynamic> json) {
    return SellerSalesPeriodItemModel(
      period: json['period'] as String,
      orderCount: json['order_count'] as int? ?? 0,
      itemQuantity: json['item_quantity'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SellerProductAnalyticsItemModel extends SellerProductAnalyticsItem {
  const SellerProductAnalyticsItemModel({
    required super.productId,
    required super.productName,
    super.sku,
    required super.revenue,
    required super.quantitySold,
    required super.currentStock,
    required super.averageRating,
    required super.reviewCount,
  });

  factory SellerProductAnalyticsItemModel.fromJson(Map<String, dynamic> json) {
    return SellerProductAnalyticsItemModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      sku: json['sku'] as String?,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      quantitySold: json['quantity_sold'] as int? ?? 0,
      currentStock: json['current_stock'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }
}
