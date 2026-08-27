import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image_placeholder.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_status_timeline.dart';

/// Premium Order Details screen displaying immutable order snapshot and cancellation action.
class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderDetailsRequested(widget.orderId));
  }

  void _confirmCancelOrder(BuildContext context, Order order) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Text(
          'Are you sure you want to cancel order #${order.orderNumber}? Product inventory will be automatically restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<OrderBloc>().add(OrderCancelled(order.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColorsLight.error,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderDetailsLoaded && state.cancellationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order has been cancelled successfully.'),
                backgroundColor: AppColorsLight.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColorsLight.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading || state is OrderInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderDetailsLoaded) {
            final order = state.order;
            final isCancelling = state.isCancelling;
            final formattedDate = DateFormat(
              'MMMM dd, yyyy • h:mm a',
            ).format(order.createdAt.toLocal());

            return RefreshIndicator(
              onRefresh: () async {
                context.read<OrderBloc>().add(
                  OrderDetailsRequested(widget.orderId),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Summary Header Card ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColorsDark.outline
                              : AppColorsLight.outline,
                        ),
                        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderNumber,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: order.status.color.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                  border: Border.all(
                                    color: order.status.color.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      order.status.icon,
                                      size: 14,
                                      color: order.status.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.status.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: order.status.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed on $formattedDate',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColorsDark.onSurfaceVariant
                                  : AppColorsLight.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Status Timeline Visual ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColorsDark.outline
                              : AppColorsLight.outline,
                        ),
                        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
                      ),
                      child: OrderStatusTimeline(currentStatus: order.status),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Purchased Items Snapshot ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColorsDark.outline
                              : AppColorsLight.outline,
                        ),
                        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items in Order (${order.itemCount})',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: AppSpacing.lg),
                            itemBuilder: (context, index) {
                              final item = order.items[index];

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child:
                                          item.productImageUrl != null &&
                                              item.productImageUrl!.isNotEmpty
                                          ? Image.network(
                                              item.productImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) =>
                                                      const ProductImagePlaceholder(
                                                        size: 60,
                                                      ),
                                            )
                                          : const ProductImagePlaceholder(
                                              size: 60,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: AppTextStyles.titleSmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.productSku != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'SKU: ${item.productSku}',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: isDark
                                                      ? AppColorsDark
                                                            .onSurfaceVariant
                                                      : AppColorsLight
                                                            .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${item.lineTotal.toStringAsFixed(2)}',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Shipping Address Snapshot ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColorsDark.outline
                              : AppColorsLight.outline,
                        ),
                        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Shipping Information',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            order.shippingAddress.fullName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.shippingAddress.phone,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.shippingAddress.formattedAddress,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColorsDark.onSurfaceVariant
                                  : AppColorsLight.onSurfaceVariant,
                            ),
                          ),
                          if (order.customerNote != null &&
                              order.customerNote!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                'Note: "${order.customerNote}"',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Payment & Price Summary ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColorsDark.outline
                              : AppColorsLight.outline,
                        ),
                        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorsLight.warning.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xs,
                                  ),
                                ),
                                child: Text(
                                  'Cash on Delivery • Pending',
                                  style: AppTextStyles.badge.copyWith(
                                    color: AppColorsLight.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildPriceRow('Subtotal', order.subtotal),
                          const SizedBox(height: AppSpacing.xs),
                          _buildPriceRow(
                            'Shipping Fee',
                            order.shippingFee,
                            isFree: order.shippingFee == 0.0,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _buildPriceRow('Tax', order.taxAmount),
                          if (order.discountAmount > 0) ...[
                            const SizedBox(height: AppSpacing.xs),
                            _buildPriceRow('Discount', -order.discountAmount),
                          ],
                          const Divider(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Paid / Due',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.price.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // ── Cancellation Button (if cancellable) ───────────────
                    if (order.status.isCancellable) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: isCancelling
                              ? null
                              : () => _confirmCancelOrder(context, order),
                          icon: isCancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.cancel_outlined,
                                  color: AppColorsLight.error,
                                ),
                          label: Text(
                            isCancelling
                                ? 'Cancelling...'
                                : 'Cancel This Order',
                            style: const TextStyle(
                              color: AppColorsLight.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColorsLight.error),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl4),
                    ],
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          isFree ? 'FREE' : '\$${amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isFree ? AppColorsLight.success : null,
          ),
        ),
      ],
    );
  }
}
