import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/order_status.dart';

/// Premium visual timeline showing the progression of order statuses.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.currentStatus});

  final OrderStatus currentStatus;

  static const List<OrderStatus> _progression = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColorsLight.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColorsLight.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel_rounded,
              color: AppColorsLight.error,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Cancelled',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColorsLight.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'This order has been cancelled and stock was restored.',
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
      );
    }

    final currentIndex = _progression.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Progress',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_progression.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Line separator between steps
              final stepBefore = index ~/ 2;
              final isPassed = currentIndex > stepBefore;

              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed
                      ? theme.colorScheme.primary
                      : (isDark
                            ? AppColorsDark.outline
                            : AppColorsLight.outline),
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final status = _progression[stepIndex];
            final isReached = currentIndex >= stepIndex;
            final isCurrent = currentIndex == stepIndex;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isReached
                        ? (isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer)
                        : (isDark
                              ? AppColorsDark.surfaceContainer
                              : AppColorsLight.surfaceContainer),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isReached
                          ? theme.colorScheme.primary
                          : (isDark
                                ? AppColorsDark.outline
                                : AppColorsLight.outline),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    status.icon,
                    size: 16,
                    color: isReached
                        ? (isCurrent
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onPrimaryContainer)
                        : (isDark
                              ? AppColorsDark.onSurfaceVariant
                              : AppColorsLight.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : (isDark
                              ? AppColorsDark.onSurfaceVariant
                              : AppColorsLight.onSurfaceVariant),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
