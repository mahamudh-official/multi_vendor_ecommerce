import 'package:equatable/equatable.dart';

class SellerAnalyticsOverview extends Equatable {
  final double totalRevenue;
  final int totalOrders;
  final int totalItemsSold;
  final double averageOrderValue;
  final int activeProducts;
  final int lowStockProducts;
  final int pendingFulfillmentCount;
  final int deliveredOrderCount;

  const SellerAnalyticsOverview({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalItemsSold,
    required this.averageOrderValue,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.pendingFulfillmentCount,
    required this.deliveredOrderCount,
  });

  @override
  List<Object?> get props => [
        totalRevenue,
        totalOrders,
        totalItemsSold,
        averageOrderValue,
        activeProducts,
        lowStockProducts,
        pendingFulfillmentCount,
        deliveredOrderCount,
      ];
}

class SellerSalesPeriodItem extends Equatable {
  final String period;
  final int orderCount;
  final int itemQuantity;
  final double revenue;

  const SellerSalesPeriodItem({
    required this.period,
    required this.orderCount,
    required this.itemQuantity,
    required this.revenue,
  });

  @override
  List<Object?> get props => [period, orderCount, itemQuantity, revenue];
}

class SellerProductAnalyticsItem extends Equatable {
  final String productId;
  final String productName;
  final String? sku;
  final double revenue;
  final int quantitySold;
  final int currentStock;
  final double averageRating;
  final int reviewCount;

  const SellerProductAnalyticsItem({
    required this.productId,
    required this.productName,
    this.sku,
    required this.revenue,
    required this.quantitySold,
    required this.currentStock,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        sku,
        revenue,
        quantitySold,
        currentStock,
        averageRating,
        reviewCount,
      ];
}
