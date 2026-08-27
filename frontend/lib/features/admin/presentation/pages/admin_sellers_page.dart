import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../../domain/entities/admin_entities.dart';
import '../bloc/admin_blocs.dart';
import '../widgets/admin_shell_scaffold.dart';

class AdminSellersPage extends StatefulWidget {
  const AdminSellersPage({super.key});

  @override
  State<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends State<AdminSellersPage> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  void _loadSellers() {
    context.read<AdminSellersBloc>().add(
      AdminSellersLoadRequested(
        search: _searchController.text.trim(),
        sellerStatus: _selectedStatus,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdminShellScaffold(
      title: 'Seller Management',
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark ? AppColorsDark.surface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search seller name or email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onSubmitted: (_) => _loadSellers(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  value: _selectedStatus,
                  hint: const Text('All Statuses'),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending Approval'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'suspended',
                      child: Text('Suspended'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _loadSellers();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadSellers,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Sellers List
          Expanded(
            child: BlocBuilder<AdminSellersBloc, AdminSellersState>(
              builder: (context, state) {
                if (state is AdminSellersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminSellersError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _loadSellers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminSellersLoaded) {
                  if (state.sellers.isEmpty) {
                    return const Center(child: Text('No sellers found.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.sellers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final seller = state.sellers[index];
                      return _buildSellerCard(context, seller);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(BuildContext context, AdminSeller seller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = seller.sellerStatus.toLowerCase();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark
                      ? AppColorsDark.accent.withValues(alpha: 0.15)
                      : AppColorsLight.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: isDark
                        ? AppColorsDark.accent
                        : AppColorsLight.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.fullName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        seller.email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColorsDark.onSurfaceVariant
                              : AppColorsLight.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Products', '${seller.productCount}'),
                _buildStatItem('Orders', '${seller.orderCount}'),
                _buildStatItem(
                  'Revenue',
                  '\$${seller.totalRevenue.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending' || status == 'suspended')
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      status == 'pending' ? 'Approve Store' : 'Reactivate',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColorsDark.success
                          : AppColorsLight.success,
                    ),
                    onPressed: () {
                      _showConfirmDialog(
                        context,
                        title: 'Approve Seller',
                        content:
                            'Approve ${seller.fullName} to sell on the platform?',
                        onConfirm: () {
                          context.read<AdminSellersBloc>().add(
                            AdminSellerStatusUpdateRequested(
                              sellerId: seller.id,
                              status: 'approved',
                            ),
                          );
                        },
                      );
                    },
                  ),
                if (status == 'approved') ...[
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.block_rounded,
                      size: 18,
                      color: isDark
                          ? AppColorsDark.error
                          : AppColorsLight.error,
                    ),
                    label: Text(
                      'Suspend Store',
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.error
                            : AppColorsLight.error,
                      ),
                    ),
                    onPressed: () {
                      _showConfirmDialog(
                        context,
                        title: 'Suspend Seller',
                        content:
                            'Suspend ${seller.fullName}? They will be blocked from creating products or fulfilling orders.',
                        onConfirm: () {
                          context.read<AdminSellersBloc>().add(
                            AdminSellerStatusUpdateRequested(
                              sellerId: seller.id,
                              status: 'suspended',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
        bg = AppColorsLight.success.withValues(alpha: 0.15);
        fg = AppColorsLight.success;
        break;
      case 'suspended':
        bg = AppColorsLight.error.withValues(alpha: 0.15);
        fg = AppColorsLight.error;
        break;
      default:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
