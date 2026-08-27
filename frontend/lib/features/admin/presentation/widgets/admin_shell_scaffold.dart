import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_event.dart';
import 'package:multi_vendor_ecommerce/features/notifications/presentation/widgets/notification_badge_icon.dart';

class AdminShellScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AdminShellScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    final navItems = [
      (Icons.dashboard_rounded, 'Dashboard', '/admin'),
      (Icons.people_alt_rounded, 'Users', '/admin/users'),
      (Icons.storefront_rounded, 'Sellers', '/admin/sellers'),
      (Icons.inventory_2_rounded, 'Products', '/admin/products'),
      (Icons.category_rounded, 'Categories', '/admin/categories'),
      (Icons.receipt_long_rounded, 'Orders', '/admin/orders'),
      (Icons.payment_rounded, 'Payments', '/admin/payments'),
      (Icons.history_rounded, 'Audit Logs', '/admin/audit-logs'),
    ];

    final currentPath = GoRouterState.of(context).matchedLocation;

    Widget drawerContent = SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: isDark
                ? AppColorsDark.surface
                : AppColorsLight.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColorsDark.primary
                        : AppColorsLight.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: isDark
                        ? AppColorsDark.onPrimary
                        : AppColorsLight.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Console',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Platform Control Center',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColorsDark.onSurfaceVariant
                              : AppColorsLight.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: navItems.map((item) {
                final isSelected = currentPath == item.$3;
                final primaryCol = isDark
                    ? AppColorsDark.accent
                    : AppColorsLight.primary;
                return ListTile(
                  leading: Icon(
                    item.$1,
                    color: isSelected
                        ? primaryCol
                        : (isDark
                              ? AppColorsDark.onSurfaceVariant
                              : AppColorsLight.onSurfaceVariant),
                  ),
                  title: Text(
                    item.$2,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? primaryCol
                          : (isDark
                                ? AppColorsDark.onSurface
                                : AppColorsLight.onSurface),
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: primaryCol.withValues(alpha: 0.1),
                  onTap: () {
                    if (!isDesktop) Navigator.of(context).pop();
                    if (!isSelected) context.go(item.$3);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: isDark ? AppColorsDark.error : AppColorsLight.error,
            ),
            title: Text(
              'Sign Out',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColorsDark.error : AppColorsLight.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/auth/login');
            },
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.titleLarge),
        elevation: 0,
        actions: [const NotificationBadgeIcon(), ...?actions],
      ),
      drawer: isDesktop ? null : Drawer(child: drawerContent),
      body: isDesktop
          ? Row(
              children: [
                SizedBox(
                  width: 260,
                  child: Material(
                    elevation: 1,
                    color: isDark ? AppColorsDark.surface : Colors.white,
                    child: drawerContent,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      floatingActionButton: floatingActionButton,
    );
  }
}
