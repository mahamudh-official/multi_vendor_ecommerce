import 'package:multi_vendor_ecommerce/features/seller/data/models/seller_order_model.dart';
import 'package:multi_vendor_ecommerce/features/seller/data/models/seller_product_model.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_dashboard_stats.dart';

class SellerDashboardStatsModel extends SellerDashboardStats {
  const SellerDashboardStatsModel({
    required super.totalProducts,
    required super.activeProducts,
    required super.inactiveProducts,
    required super.lowStockProducts,
    required super.totalOrders,
    required super.pendingOrders,
    required super.processingOrders,
    required super.shippedOrders,
    required super.deliveredOrders,
    required super.totalSalesAmount,
  });

  factory SellerDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return SellerDashboardStatsModel(
      totalProducts: json['total_products'] as int? ?? 0,
      activeProducts: json['active_products'] as int? ?? 0,
      inactiveProducts: json['inactive_products'] as int? ?? 0,
      lowStockProducts: json['low_stock_products'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      pendingOrders: json['pending_orders'] as int? ?? 0,
      processingOrders: json['processing_orders'] as int? ?? 0,
      shippedOrders: json['shipped_orders'] as int? ?? 0,
      deliveredOrders: json['delivered_orders'] as int? ?? 0,
      totalSalesAmount: (json['total_sales_amount'] is String)
          ? double.tryParse(json['total_sales_amount'] as String) ?? 0.0
          : (json['total_sales_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SellerDashboardModel extends SellerDashboard {
  const SellerDashboardModel({
    required super.stats,
    required super.recentOrders,
    required super.lowStockProducts,
  });

  factory SellerDashboardModel.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>;
    final stats = SellerDashboardStatsModel.fromJson(statsJson);

    final recentOrdersJson = json['recent_orders'] as List<dynamic>? ?? [];
    final recentOrders = recentOrdersJson
        .map((o) => SellerOrderModel.fromJson(o as Map<String, dynamic>))
        .toList();

    final lowStockJson = json['low_stock_products'] as List<dynamic>? ?? [];
    final lowStockProducts = lowStockJson
        .map((p) => SellerProductModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return SellerDashboardModel(
      stats: stats,
      recentOrders: recentOrders,
      lowStockProducts: lowStockProducts,
    );
  }
}
