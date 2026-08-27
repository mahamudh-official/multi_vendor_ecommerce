import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_state.dart';
import 'package:multi_vendor_ecommerce/features/notifications/presentation/widgets/notification_badge_icon.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_dashboard/seller_dashboard_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/widgets/seller_order_card.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/widgets/seller_product_card.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/widgets/seller_stat_card.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerDashboardBloc>().add(const SellerDashboardRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const NotificationBadgeIcon(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              context.read<SellerDashboardBloc>().add(
                const SellerDashboardRefreshed(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SellerDashboardBloc, SellerDashboardState>(
        builder: (context, state) {
          if (state is SellerDashboardLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (state is SellerDashboardFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SellerDashboardBloc>().add(
                          const SellerDashboardRequested(),
                        );
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SellerDashboardLoaded) {
            final dashboard = state.dashboard;
            final stats = dashboard.stats;

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                context.read<SellerDashboardBloc>().add(
                  const SellerDashboardRefreshed(),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Profile Summary ──────────────────────────
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final user = authState is Authenticated
                            ? authState.user
                            : null;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF1E293B),
                                      const Color(0xFF0F172A),
                                    ]
                                  : [
                                      primaryColor.withValues(alpha: 0.08),
                                      Colors.white,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: primaryColor.withValues(alpha: 0.2),
                                child: Text(
                                  (user?.fullName.isNotEmpty ?? false)
                                      ? user!.fullName[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Seller Portal',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      user?.email ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : AppColorsLight.neutral600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Seller',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Quick Actions ─────────────────────────────────────
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/seller/products/create'),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/seller/orders'),
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 18,
                            ),
                            label: const Text('Orders'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── KPI / Stat Grid ───────────────────────────────────
                    Text(
                      'Performance & Overview',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600
                            ? 3
                            : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          children: [
                            SellerStatCard(
                              title: 'Total Sales',
                              value:
                                  '\$${stats.totalSalesAmount.toStringAsFixed(2)}',
                              icon: Icons.monetization_on_outlined,
                              color: const Color(0xFF10B981),
                            ),
                            SellerStatCard(
                              title: 'Total Orders',
                              value: '${stats.totalOrders}',
                              icon: Icons.shopping_bag_outlined,
                              color: const Color(0xFF3B82F6),
                              onTap: () => context.push('/seller/orders'),
                            ),
                            SellerStatCard(
                              title: 'Pending Orders',
                              value: '${stats.pendingOrders}',
                              icon: Icons.hourglass_top_rounded,
                              color: const Color(0xFFF59E0B),
                              onTap: () =>
                                  context.push('/seller/orders?status=pending'),
                            ),
                            SellerStatCard(
                              title: 'Active Products',
                              value: '${stats.activeProducts}',
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF06B6D4),
                              onTap: () => context.push(
                                '/seller/products?is_active=true',
                              ),
                            ),
                            SellerStatCard(
                              title: 'Low Stock Alert',
                              value: '${stats.lowStockProducts}',
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                              onTap: () => context.push(
                                '/seller/products?low_stock=true',
                              ),
                            ),
                            SellerStatCard(
                              title: 'Total Products',
                              value: '${stats.totalProducts}',
                              icon: Icons.inventory_2_outlined,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => context.push('/seller/products'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Low Stock Products Section ────────────────────────
                    if (dashboard.lowStockProducts.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Needs Attention (Low Stock)',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFEF4444),
                                ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push('/seller/products?low_stock=true'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...dashboard.lowStockProducts.map(
                        (p) => SellerProductCard(
                          product: p,
                          onEdit: () =>
                              context.push('/seller/products/${p.id}/edit'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Recent Orders Section ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Orders',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () => context.push('/seller/orders'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (dashboard.recentOrders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No recent orders yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...dashboard.recentOrders.map(
                        (order) => SellerOrderCard(
                          order: order,
                          onTap: () =>
                              context.push('/seller/orders/${order.id}'),
                        ),
                      ),
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
}
