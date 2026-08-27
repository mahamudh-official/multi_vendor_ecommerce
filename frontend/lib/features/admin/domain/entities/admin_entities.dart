import 'package:equatable/equatable.dart';

/// Aggregated dashboard statistics for platform administration.
class AdminDashboardStats extends Equatable {
  final int totalUsers;
  final int totalCustomers;
  final int totalSellers;
  final int activeSellers;
  final int pendingSellers;

  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int lowStockProducts;

  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;

  final double totalRevenue;
  final double todayRevenue;
  final double monthRevenue;

  final int totalPayments;
  final int successfulPayments;
  final int failedPayments;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalCustomers,
    required this.totalSellers,
    required this.activeSellers,
    required this.pendingSellers,
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.lowStockProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.totalPayments,
    required this.successfulPayments,
    required this.failedPayments,
  });

  @override
  List<Object?> get props => [
    totalUsers,
    totalCustomers,
    totalSellers,
    activeSellers,
    pendingSellers,
    totalProducts,
    activeProducts,
    inactiveProducts,
    lowStockProducts,
    totalOrders,
    pendingOrders,
    confirmedOrders,
    processingOrders,
    shippedOrders,
    deliveredOrders,
    cancelledOrders,
    totalRevenue,
    todayRevenue,
    monthRevenue,
    totalPayments,
    successfulPayments,
    failedPayments,
  ];
}

/// User profile representation in admin console.
class AdminUser extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? sellerStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.sellerStatus,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    role,
    sellerStatus,
    isActive,
    createdAt,
    updatedAt,
  ];
}

/// Seller store representation in admin console.
class AdminSeller extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String sellerStatus;
  final bool isActive;
  final int productCount;
  final int orderCount;
  final double totalRevenue;
  final DateTime createdAt;

  const AdminSeller({
    required this.id,
    required this.fullName,
    required this.email,
    required this.sellerStatus,
    required this.isActive,
    required this.productCount,
    required this.orderCount,
    required this.totalRevenue,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    sellerStatus,
    isActive,
    productCount,
    orderCount,
    totalRevenue,
    createdAt,
  ];
}

/// Product moderation entity.
class AdminProduct extends Equatable {
  final String id;
  final String sellerId;
  final String? sellerName;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String? sku;
  final String? imageUrl;
  final bool isActive;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminProduct({
    required this.id,
    required this.sellerId,
    this.sellerName,
    required this.categoryId,
    this.categoryName,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.compareAtPrice,
    required this.stockQuantity,
    this.sku,
    this.imageUrl,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    sellerId,
    sellerName,
    categoryId,
    categoryName,
    name,
    slug,
    description,
    price,
    compareAtPrice,
    stockQuantity,
    sku,
    imageUrl,
    isActive,
    isFeatured,
    createdAt,
    updatedAt,
  ];
}

/// Category management entity.
class AdminCategory extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int productCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.productCount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    imageUrl,
    isActive,
    productCount,
    createdAt,
    updatedAt,
  ];
}

/// Order item snapshot for admin oversight.
class AdminOrderItem extends Equatable {
  final String id;
  final String productId;
  final String sellerId;
  final String? sellerName;
  final String productName;
  final String? productSku;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String fulfillmentStatus;

  const AdminOrderItem({
    required this.id,
    required this.productId,
    required this.sellerId,
    this.sellerName,
    required this.productName,
    this.productSku,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.fulfillmentStatus,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    sellerId,
    sellerName,
    productName,
    productSku,
    productImageUrl,
    unitPrice,
    quantity,
    lineTotal,
    fulfillmentStatus,
  ];
}

/// Order representation in admin console.
class AdminOrder extends Equatable {
  final String id;
  final String userId;
  final String? customerEmail;
  final String? customerName;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double shippingFee;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String shippingFullName;
  final String shippingPhone;
  final String shippingAddressLine1;
  final String? shippingAddressLine2;
  final String shippingCity;
  final String shippingState;
  final String shippingPostalCode;
  final String shippingCountry;
  final String? customerNote;
  final DateTime createdAt;
  final List<AdminOrderItem> items;
  final int sellerCount;

  const AdminOrder({
    required this.id,
    required this.userId,
    this.customerEmail,
    this.customerName,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    required this.shippingFullName,
    required this.shippingPhone,
    required this.shippingAddressLine1,
    this.shippingAddressLine2,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingPostalCode,
    required this.shippingCountry,
    this.customerNote,
    required this.createdAt,
    required this.items,
    required this.sellerCount,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    customerEmail,
    customerName,
    orderNumber,
    status,
    paymentStatus,
    subtotal,
    shippingFee,
    discountAmount,
    taxAmount,
    totalAmount,
    currency,
    shippingFullName,
    shippingPhone,
    shippingAddressLine1,
    shippingAddressLine2,
    shippingCity,
    shippingState,
    shippingPostalCode,
    shippingCountry,
    customerNote,
    createdAt,
    items,
    sellerCount,
  ];
}

/// Payment transaction in admin console.
class AdminPayment extends Equatable {
  final String id;
  final String orderId;
  final String? orderNumber;
  final String userId;
  final String? customerEmail;
  final double amount;
  final String currency;
  final String status;
  final String provider;
  final String? providerPaymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminPayment({
    required this.id,
    required this.orderId,
    this.orderNumber,
    required this.userId,
    this.customerEmail,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    this.providerPaymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    orderId,
    orderNumber,
    userId,
    customerEmail,
    amount,
    currency,
    status,
    provider,
    providerPaymentId,
    createdAt,
    updatedAt,
  ];
}

/// Immutable audit log entry in admin console.
class AdminAuditLog extends Equatable {
  final String id;
  final String? adminUserId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AdminAuditLog({
    required this.id,
    this.adminUserId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.metadata,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    adminUserId,
    action,
    entityType,
    entityId,
    metadata,
    createdAt,
  ];
}
