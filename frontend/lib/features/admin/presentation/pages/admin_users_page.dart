import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../../domain/entities/admin_entities.dart';
import '../bloc/admin_blocs.dart';
import '../widgets/admin_shell_scaffold.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    context.read<AdminUsersBloc>().add(
      AdminUsersLoadRequested(
        search: _searchController.text.trim(),
        role: _selectedRole,
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
      title: 'User Management',
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
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onSubmitted: (_) => _loadUsers(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  value: _selectedRole,
                  hint: const Text('All Roles'),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Roles')),
                    DropdownMenuItem(
                      value: 'customer',
                      child: Text('Customer'),
                    ),
                    DropdownMenuItem(value: 'seller', child: Text('Seller')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedRole = val);
                    _loadUsers();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadUsers,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // User List
          Expanded(
            child: BlocBuilder<AdminUsersBloc, AdminUsersState>(
              builder: (context, state) {
                if (state is AdminUsersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminUsersError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminUsersLoaded) {
                  if (state.users.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      return _buildUserCard(context, user);
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

  Widget _buildUserCard(BuildContext context, AdminUser user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? (isDark
                    ? AppColorsDark.accent.withValues(alpha: 0.15)
                    : AppColorsLight.primary.withValues(alpha: 0.15))
              : Colors.grey.shade300,
          child: Icon(
            user.role == 'admin'
                ? Icons.admin_panel_settings_rounded
                : (user.role == 'seller'
                      ? Icons.storefront_rounded
                      : Icons.person_rounded),
            color: user.isActive
                ? (isDark ? AppColorsDark.accent : AppColorsLight.primary)
                : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Text(
              user.fullName,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${user.email} • Joined ${user.createdAt.toLocal().toString().split(' ')[0]}',
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColorsDark.onSurfaceVariant
                : AppColorsLight.onSurfaceVariant,
          ),
        ),
        trailing: user.role == 'admin'
            ? null
            : Switch(
                value: user.isActive,
                activeThumbColor: isDark
                    ? AppColorsDark.success
                    : AppColorsLight.success,
                onChanged: (val) {
                  _showConfirmDialog(
                    context,
                    title: val ? 'Activate User' : 'Deactivate User',
                    content:
                        'Are you sure you want to ${val ? 'activate' : 'deactivate'} ${user.fullName}?',
                    onConfirm: () {
                      context.read<AdminUsersBloc>().add(
                        AdminUserStatusUpdateRequested(
                          userId: user.id,
                          isActive: val,
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'seller':
        return Colors.orange;
      default:
        return Colors.blue;
    }
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
