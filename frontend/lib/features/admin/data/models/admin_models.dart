import '../../domain/entities/admin_entities.dart';

class AdminDashboardStatsModel extends AdminDashboardStats {
  const AdminDashboardStatsModel({
    required super.totalUsers,
    required super.totalCustomers,
    required super.totalSellers,
    required super.activeSellers,
    required super.pendingSellers,
    required super.totalProducts,
    required super.activeProducts,
    required super.inactiveProducts,
    required super.lowStockProducts,
    required super.totalOrders,
    required super.pendingOrders,
    required super.confirmedOrders,
    required super.processingOrders,
    required super.shippedOrders,
    required super.deliveredOrders,
    required super.cancelledOrders,
    required super.totalRevenue,
    required super.todayRevenue,
    required super.monthRevenue,
    required super.totalPayments,
    required super.successfulPayments,
    required super.failedPayments,
  });

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      totalUsers: json['total_users'] as int? ?? 0,
      totalCustomers: json['total_customers'] as int? ?? 0,
      totalSellers: json['total_sellers'] as int? ?? 0,
      activeSellers: json['active_sellers'] as int? ?? 0,
      pendingSellers: json['pending_sellers'] as int? ?? 0,
      totalProducts: json['total_products'] as int? ?? 0,
      activeProducts: json['active_products'] as int? ?? 0,
      inactiveProducts: json['inactive_products'] as int? ?? 0,
      lowStockProducts: json['low_stock_products'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      pendingOrders: json['pending_orders'] as int? ?? 0,
      confirmedOrders: json['confirmed_orders'] as int? ?? 0,
      processingOrders: json['processing_orders'] as int? ?? 0,
      shippedOrders: json['shipped_orders'] as int? ?? 0,
      deliveredOrders: json['delivered_orders'] as int? ?? 0,
      cancelledOrders: json['cancelled_orders'] as int? ?? 0,
      totalRevenue:
          (num.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0)
              .toDouble(),
      todayRevenue:
          (num.tryParse(json['today_revenue']?.toString() ?? '0') ?? 0)
              .toDouble(),
      monthRevenue:
          (num.tryParse(json['month_revenue']?.toString() ?? '0') ?? 0)
              .toDouble(),
      totalPayments: json['total_payments'] as int? ?? 0,
      successfulPayments: json['successful_payments'] as int? ?? 0,
      failedPayments: json['failed_payments'] as int? ?? 0,
    );
  }
}

class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.sellerStatus,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      sellerStatus: json['seller_status'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class AdminSellerModel extends AdminSeller {
  const AdminSellerModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.sellerStatus,
    required super.isActive,
    required super.productCount,
    required super.orderCount,
    required super.totalRevenue,
    required super.createdAt,
  });

  factory AdminSellerModel.fromJson(Map<String, dynamic> json) {
    return AdminSellerModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      sellerStatus: json['seller_status'] as String? ?? 'approved',
      isActive: json['is_active'] as bool? ?? true,
      productCount: json['product_count'] as int? ?? 0,
      orderCount: json['order_count'] as int? ?? 0,
      totalRevenue:
          (num.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0)
              .toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminProductModel extends AdminProduct {
  const AdminProductModel({
    required super.id,
    required super.sellerId,
    super.sellerName,
    required super.categoryId,
    super.categoryName,
    required super.name,
    required super.slug,
    super.description,
    required super.price,
    super.compareAtPrice,
    required super.stockQuantity,
    super.sku,
    super.imageUrl,
    required super.isActive,
    required super.isFeatured,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    return AdminProductModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String?,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: (num.tryParse(json['price']?.toString() ?? '0') ?? 0).toDouble(),
      compareAtPrice: json['compare_at_price'] != null
          ? (num.tryParse(json['compare_at_price']?.toString() ?? '0') ?? 0)
                .toDouble()
          : null,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class AdminCategoryModel extends AdminCategory {
  const AdminCategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    super.imageUrl,
    required super.isActive,
    required super.productCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      productCount: json['product_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class AdminOrderItemModel extends AdminOrderItem {
  const AdminOrderItemModel({
    required super.id,
    required super.productId,
    required super.sellerId,
    super.sellerName,
    required super.productName,
    super.productSku,
    super.productImageUrl,
    required super.unitPrice,
    required super.quantity,
    required super.lineTotal,
    required super.fulfillmentStatus,
  });

  factory AdminOrderItemModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String?,
      productName: json['product_name'] as String,
      productSku: json['product_sku'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      unitPrice: (num.tryParse(json['unit_price']?.toString() ?? '0') ?? 0)
          .toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      lineTotal: (num.tryParse(json['line_total']?.toString() ?? '0') ?? 0)
          .toDouble(),
      fulfillmentStatus: json['fulfillment_status'] as String? ?? 'pending',
    );
  }
}

class AdminOrderModel extends AdminOrder {
  const AdminOrderModel({
    required super.id,
    required super.userId,
    super.customerEmail,
    super.customerName,
    required super.orderNumber,
    required super.status,
    required super.paymentStatus,
    required super.subtotal,
    required super.shippingFee,
    required super.discountAmount,
    required super.taxAmount,
    required super.totalAmount,
    required super.currency,
    required super.shippingFullName,
    required super.shippingPhone,
    required super.shippingAddressLine1,
    super.shippingAddressLine2,
    required super.shippingCity,
    required super.shippingState,
    required super.shippingPostalCode,
    required super.shippingCountry,
    super.customerNote,
    required super.createdAt,
    required super.items,
    required super.sellerCount,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((i) => AdminOrderItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return AdminOrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      customerEmail: json['customer_email'] as String?,
      customerName: json['customer_name'] as String?,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      subtotal: (num.tryParse(json['subtotal']?.toString() ?? '0') ?? 0)
          .toDouble(),
      shippingFee: (num.tryParse(json['shipping_fee']?.toString() ?? '0') ?? 0)
          .toDouble(),
      discountAmount:
          (num.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0)
              .toDouble(),
      taxAmount: (num.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0)
          .toDouble(),
      totalAmount: (num.tryParse(json['total_amount']?.toString() ?? '0') ?? 0)
          .toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      shippingFullName: json['shipping_full_name'] as String,
      shippingPhone: json['shipping_phone'] as String,
      shippingAddressLine1: json['shipping_address_line1'] as String,
      shippingAddressLine2: json['shipping_address_line2'] as String?,
      shippingCity: json['shipping_city'] as String,
      shippingState: json['shipping_state'] as String,
      shippingPostalCode: json['shipping_postal_code'] as String,
      shippingCountry: json['shipping_country'] as String,
      customerNote: json['customer_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
      sellerCount: json['seller_count'] as int? ?? 0,
    );
  }
}

class AdminPaymentModel extends AdminPayment {
  const AdminPaymentModel({
    required super.id,
    required super.orderId,
    super.orderNumber,
    required super.userId,
    super.customerEmail,
    required super.amount,
    required super.currency,
    required super.status,
    required super.provider,
    super.providerPaymentId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminPaymentModel.fromJson(Map<String, dynamic> json) {
    return AdminPaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String?,
      userId: json['user_id'] as String,
      customerEmail: json['customer_email'] as String?,
      amount: (num.tryParse(json['amount']?.toString() ?? '0') ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String,
      provider: json['provider'] as String,
      providerPaymentId: json['provider_payment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class AdminAuditLogModel extends AdminAuditLog {
  const AdminAuditLogModel({
    required super.id,
    super.adminUserId,
    required super.action,
    required super.entityType,
    required super.entityId,
    required super.metadata,
    required super.createdAt,
  });

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogModel(
      id: json['id'] as String,
      adminUserId: json['admin_user_id'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      metadata:
          (json['metadata_json'] ?? json['metadata'] ?? {})
              as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
