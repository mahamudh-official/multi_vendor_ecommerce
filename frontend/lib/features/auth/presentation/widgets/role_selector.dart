import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Premium segmented card selector for choosing account role (Customer vs Seller).
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            role: 'customer',
            title: 'Buyer',
            subtitle: 'Shop products',
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag_rounded,
            isSelected: selectedRole == 'customer',
            isDark: isDark,
            onTap: () => onRoleChanged('customer'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _RoleCard(
            role: 'seller',
            title: 'Seller',
            subtitle: 'Sell & manage store',
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront_rounded,
            isSelected: selectedRole == 'seller',
            isDark: isDark,
            onTap: () => onRoleChanged('seller'),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title account type',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: isDark ? 0.18 : 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? primary : theme.colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    size: 24,
                    color: isSelected
                        ? primary
                        : (isDark
                              ? AppColorsDark.onSurfaceVariant
                              : AppColorsLight.onSurfaceVariant),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, size: 18, color: primary),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isSelected ? primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColorsDark.onSurfaceVariant
                      : AppColorsLight.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
