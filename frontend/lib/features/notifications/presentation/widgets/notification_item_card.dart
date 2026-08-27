import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/entities/app_notification.dart';
import 'package:multi_vendor_ecommerce/features/notifications/presentation/bloc/notification_bloc.dart';

class NotificationItemCard extends StatelessWidget {
  final AppNotification notification;

  const NotificationItemCard({super.key, required this.notification});

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleTap(BuildContext context) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        NotificationReadMarked(notificationId: notification.id),
      );
    }

    final data = notification.data;
    if (data != null && data.containsKey('order_id')) {
      final orderId = data['order_id'] as String?;
      if (orderId != null && orderId.isNotEmpty) {
        context.push('/orders/$orderId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = notification.type;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: notification.isRead
          ? (isDark ? AppColorsDark.surface : AppColorsLight.surface)
          : (type.color.withValues(alpha: isDark ? 0.12 : 0.06)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: notification.isRead
              ? (isDark ? AppColorsDark.outline : AppColorsLight.outline)
              : type.color.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type Icon Badge ───────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, color: type.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Details ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColorsLight.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          _formatTime(notification.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColorsDark.onSurfaceVariant
                                : AppColorsLight.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
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
      ),
    );
  }
}
