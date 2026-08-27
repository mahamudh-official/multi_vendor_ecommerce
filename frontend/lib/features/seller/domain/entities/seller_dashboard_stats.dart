import 'package:equatable/equatable.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_order.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_product.dart';

class SellerDashboardStats extends Equatable {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int lowStockProducts;
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final double totalSalesAmount;

  const SellerDashboardStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.lowStockProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.totalSalesAmount,
  });

  @override
  List<Object?> get props => [
    totalProducts,
    activeProducts,
    inactiveProducts,
    lowStockProducts,
    totalOrders,
    pendingOrders,
    processingOrders,
    shippedOrders,
    deliveredOrders,
    totalSalesAmount,
  ];
}

class SellerDashboard extends Equatable {
  final SellerDashboardStats stats;
  final List<SellerOrder> recentOrders;
  final List<SellerProduct> lowStockProducts;

  const SellerDashboard({
    required this.stats,
    required this.recentOrders,
    required this.lowStockProducts,
  });

  @override
  List<Object?> get props => [stats, recentOrders, lowStockProducts];
}
