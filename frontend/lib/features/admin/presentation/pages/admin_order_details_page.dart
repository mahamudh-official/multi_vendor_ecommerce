import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../bloc/admin_blocs.dart';

class AdminOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailsPage({super.key, required this.orderId});

  @override
  State<AdminOrderDetailsPage> createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminOrdersBloc>().add(
      AdminOrderDetailsRequested(widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: BlocBuilder<AdminOrdersBloc, AdminOrdersState>(
        builder: (context, state) {
          if (state is AdminOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminOrdersError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () => context.read<AdminOrdersBloc>().add(
                      AdminOrderDetailsRequested(widget.orderId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AdminOrdersLoaded && state.selectedOrder != null) {
            final order = state.selectedOrder!;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Header Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.orderNumber,
                              style: AppTextStyles.titleLarge,
                            ),
                            Text(
                              '\$${order.totalAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: isDark
                                    ? AppColorsDark.accent
                                    : AppColorsLight.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Placed: ${order.createdAt.toLocal().toString().split('.')[0]}',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _buildBadge(
                              'STATUS: ${order.status.toUpperCase()}',
                              Colors.blue,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _buildBadge(
                              'PAYMENT: ${order.paymentStatus.toUpperCase()}',
                              order.paymentStatus == 'paid'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Customer & Shipping Info
                Text(
                  'Customer & Delivery Snapshot',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${order.shippingFullName}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Email: ${order.customerEmail ?? 'N/A'}',
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          'Phone: ${order.shippingPhone}',
                          style: AppTextStyles.bodySmall,
                        ),
                        const Divider(),
                        Text(
                          'Address: ${order.shippingAddressLine1}${order.shippingAddressLine2 != null ? ', ${order.shippingAddressLine2}' : ''}, ${order.shippingCity}, ${order.shippingState} ${order.shippingPostalCode}, ${order.shippingCountry}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Multi-Vendor Items
                Text(
                  'Order Items (${order.items.length})',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...order.items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: ListTile(
                      title: Text(
                        item.productName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seller ID: ${item.sellerId} • SKU: ${item.productSku ?? 'N/A'}',
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            'Qty: ${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)} = \$${item.lineTotal.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            'Fulfillment: ${item.fulfillmentStatus.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
