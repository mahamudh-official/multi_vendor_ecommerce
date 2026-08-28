import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/widgets/primary_button.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/entities/seller_analytics.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_event.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_state.dart';

class SellerAnalyticsPage extends StatefulWidget {
  const SellerAnalyticsPage({super.key});

  @override
  State<SellerAnalyticsPage> createState() => _SellerAnalyticsPageState();
}

class _SellerAnalyticsPageState extends State<SellerAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerAnalyticsBloc>().add(const LoadSellerAnalyticsEvent(period: 'daily'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Seller Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SellerAnalyticsBloc>().add(const LoadSellerAnalyticsEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<SellerAnalyticsBloc, SellerAnalyticsState>(
        builder: (context, state) {
          if (state is SellerAnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerAnalyticsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Retry',
                      onPressed: () {
                        context.read<SellerAnalyticsBloc>().add(const LoadSellerAnalyticsEvent());
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is SellerAnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SellerAnalyticsBloc>().add(LoadSellerAnalyticsEvent(period: state.activePeriod));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildKpiGrid(state.overview),
                  const SizedBox(height: 20),
                  _buildSalesSection(state),
                  const SizedBox(height: 20),
                  _buildTopProductsSection(state.topProducts),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildKpiGrid(SellerAnalyticsOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview KPIs',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildKpiCard('Total Revenue', '\$${overview.totalRevenue.toStringAsFixed(2)}', Icons.attach_money, AppColors.success),
            _buildKpiCard('Total Orders', '${overview.totalOrders}', Icons.shopping_bag_outlined, AppColors.primary),
            _buildKpiCard('Units Sold', '${overview.totalItemsSold}', Icons.inventory_2_outlined, Colors.indigo),
            _buildKpiCard('Avg Order Value', '\$${overview.averageOrderValue.toStringAsFixed(2)}', Icons.trending_up, Colors.purple),
            _buildKpiCard('Active Products', '${overview.activeProducts}', Icons.check_circle_outline, Colors.teal),
            _buildKpiCard('Low Stock Items', '${overview.lowStockProducts}', Icons.warning_amber_rounded, AppColors.warning),
            _buildKpiCard('Pending Fulfillment', '${overview.pendingFulfillmentCount}', Icons.hourglass_top, Colors.orange),
            _buildKpiCard('Delivered Orders', '${overview.deliveredOrderCount}', Icons.local_shipping_outlined, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesSection(SellerAnalyticsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('Daily', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'weekly', label: Text('Weekly', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'monthly', label: Text('Monthly', style: TextStyle(fontSize: 12))),
                ],
                selected: {state.activePeriod},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    context.read<SellerAnalyticsBloc>().add(ChangeSalesPeriodEvent(period: set.first));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.salesTimeline.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No sales recorded for this period',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.salesTimeline.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = state.salesTimeline[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.period, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${item.orderCount} orders • ${item.itemQuantity} items',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        '\$${item.revenue.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(List<SellerProductAnalyticsItem> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performing Products',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No product sales data available', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final prod = products[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.productName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  '${prod.averageRating} (${prod.reviewCount})',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stock: ${prod.currentStock}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: prod.currentStock <= 5 ? AppColors.warning : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${prod.revenue.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${prod.quantitySold} sold',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
