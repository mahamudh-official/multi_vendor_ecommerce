import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_orders/seller_orders_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/widgets/fulfillment_timeline_card.dart';

class SellerOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const SellerOrderDetailsPage({super.key, required this.orderId});

  @override
  State<SellerOrderDetailsPage> createState() => _SellerOrderDetailsPageState();
}

class _SellerOrderDetailsPageState extends State<SellerOrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerOrdersBloc>().add(
      SellerOrderDetailsRequested(orderId: widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Fulfillment',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocConsumer<SellerOrdersBloc, SellerOrdersState>(
        listener: (context, state) {
          if (state is SellerOrderStatusUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          } else if (state is SellerOrdersFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SellerOrdersLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (state is SellerOrderDetailsLoaded ||
              state is SellerOrderStatusUpdating ||
              state is SellerOrderStatusUpdateSuccess) {
            final order = (state is SellerOrderDetailsLoaded)
                ? state.order
                : (state is SellerOrderStatusUpdateSuccess)
                ? state.updatedOrder
                : (context.read<SellerOrdersBloc>().state
                          as SellerOrderDetailsLoaded)
                      .order;

            final isUpdating = state is SellerOrderStatusUpdating;
            final dateStr = DateFormat(
              'MMMM dd, yyyy • hh:mm a',
            ).format(order.createdAt);

            // Dominant fulfillment status among seller items
            final dominantFulfillment = order.items.isNotEmpty
                ? order.items.first.fulfillmentStatus
                : FulfillmentStatus.pending;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Order Header Card ─────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.orderNumber,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: order.status.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: order.status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : AppColorsLight.neutral600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Customer: ${order.customerName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (order.shippingCity != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Destination: ${order.shippingCity}, ${order.shippingCountry}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[300]
                                      : AppColorsLight.neutral700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Fulfillment Timeline & Actions ────────────────────
                  FulfillmentTimelineCard(
                    currentStatus: dominantFulfillment,
                    isUpdating: isUpdating,
                    onAdvanceStatus: (nextStatus) {
                      context.read<SellerOrdersBloc>().add(
                        SellerOrderStatusUpdated(
                          orderId: order.id,
                          status: nextStatus,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── "Your Items" Section ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Items in this Order',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${order.items.length} item(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColorsLight.neutral600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 56,
                              height: 56,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              child:
                                  item.productImageUrl != null &&
                                      item.productImageUrl!.isNotEmpty
                                  ? Image.network(
                                      item.productImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : AppColorsLight.neutral600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.lineTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // ── Subtotal Summary ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Revenue Subtotal:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '\$${order.sellerSubtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
