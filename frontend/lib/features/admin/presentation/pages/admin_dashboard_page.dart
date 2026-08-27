import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../bloc/admin_blocs.dart';
import '../widgets/admin_shell_scaffold.dart';
import '../widgets/admin_stat_card.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardBloc>().add(AdminDashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellScaffold(
      title: 'Platform Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<AdminDashboardBloc>().add(
            AdminDashboardLoadRequested(),
          ),
        ),
      ],
      body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        builder: (context, state) {
          if (state is AdminDashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminDashboardError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColorsLight.error,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(state.message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => context.read<AdminDashboardBloc>().add(
                      AdminDashboardLoadRequested(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AdminDashboardLoaded) {
            final s = state.stats;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminDashboardBloc>().add(
                  AdminDashboardLoadRequested(),
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text('Financial Overview', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 800 ? 3 : 1;
                      return GridView.count(
                        crossAxisCount: cols,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: cols == 3 ? 2.2 : 2.5,
                        children: [
                          AdminStatCard(
                            title: 'Total Revenue (Paid)',
                            value: '\$${s.totalRevenue.toStringAsFixed(2)}',
                            subtitle: 'All-time successful orders',
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: AppColorsLight.success,
                          ),
                          AdminStatCard(
                            title: 'Today Revenue',
                            value: '\$${s.todayRevenue.toStringAsFixed(2)}',
                            subtitle: 'Collected today',
                            icon: Icons.today_rounded,
                            iconColor: AppColorsLight.primary,
                          ),
                          AdminStatCard(
                            title: 'Month Revenue',
                            value: '\$${s.monthRevenue.toStringAsFixed(2)}',
                            subtitle: 'Collected this calendar month',
                            icon: Icons.calendar_month_rounded,
                            iconColor: AppColorsLight.accent,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Marketplace & Entity Statistics',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 800
                          ? 4
                          : (constraints.maxWidth > 500 ? 2 : 1);
                      return GridView.count(
                        crossAxisCount: cols,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.8,
                        children: [
                          AdminStatCard(
                            title: 'Total Users',
                            value: '${s.totalUsers}',
                            subtitle: '${s.totalCustomers} customers',
                            icon: Icons.people_alt_rounded,
                            iconColor: Colors.blue,
                          ),
                          AdminStatCard(
                            title: 'Active Sellers',
                            value: '${s.activeSellers} / ${s.totalSellers}',
                            subtitle: '${s.pendingSellers} pending approvals',
                            icon: Icons.storefront_rounded,
                            iconColor: Colors.orange,
                          ),
                          AdminStatCard(
                            title: 'Total Products',
                            value: '${s.totalProducts}',
                            subtitle:
                                '${s.activeProducts} active, ${s.lowStockProducts} low stock',
                            icon: Icons.inventory_2_rounded,
                            iconColor: Colors.purple,
                          ),
                          AdminStatCard(
                            title: 'Total Orders',
                            value: '${s.totalOrders}',
                            subtitle:
                                '${s.deliveredOrders} delivered, ${s.cancelledOrders} cancelled',
                            icon: Icons.receipt_long_rounded,
                            iconColor: Colors.teal,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Order Lifecycle Health',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        _buildStatusRow(
                          context,
                          'Pending Orders',
                          s.pendingOrders,
                          Colors.amber,
                        ),
                        const Divider(),
                        _buildStatusRow(
                          context,
                          'Confirmed Orders',
                          s.confirmedOrders,
                          Colors.blue,
                        ),
                        const Divider(),
                        _buildStatusRow(
                          context,
                          'Processing Orders',
                          s.processingOrders,
                          Colors.indigo,
                        ),
                        const Divider(),
                        _buildStatusRow(
                          context,
                          'Shipped Orders',
                          s.shippedOrders,
                          Colors.deepPurple,
                        ),
                        const Divider(),
                        _buildStatusRow(
                          context,
                          'Delivered Orders',
                          s.deliveredOrders,
                          Colors.green,
                        ),
                        const Divider(),
                        _buildStatusRow(
                          context,
                          'Cancelled Orders',
                          s.cancelledOrders,
                          Colors.red,
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

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
          Text(
            '$count',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
