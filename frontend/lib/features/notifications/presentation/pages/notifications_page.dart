import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';
import 'package:multi_vendor_ecommerce/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:multi_vendor_ecommerce/features/notifications/presentation/widgets/notification_item_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(
      NotificationsRequested(unreadOnly: _unreadOnly, refresh: true),
    );
  }

  void _loadNotifications({bool? unreadOnly}) {
    final filter = unreadOnly ?? _unreadOnly;
    setState(() => _unreadOnly = filter);
    context.read<NotificationBloc>().add(
      NotificationsRequested(unreadOnly: filter, refresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      const AllNotificationsReadMarked(),
                    );
                  },
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark all read'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColorsLight.primary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Chips Bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: !_unreadOnly,
                  onSelected: (selected) {
                    if (selected) _loadNotifications(unreadOnly: false);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    final unreadCount = state.unreadCount;
                    return FilterChip(
                      label: Text(
                        unreadCount > 0 ? 'Unread ($unreadCount)' : 'Unread',
                      ),
                      selected: _unreadOnly,
                      onSelected: (selected) {
                        _loadNotifications(unreadOnly: selected);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Notifications List ────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is NotificationFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(state.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => _loadNotifications(),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is NotificationLoaded) {
                  final list = state.notifications;
                  if (list.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async => _loadNotifications(),
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 56,
                                    color: isDark
                                        ? AppColorsDark.onSurfaceVariant
                                        : AppColorsLight.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    _unreadOnly
                                        ? 'No unread notifications'
                                        : 'No notifications yet',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Updates on your orders and payments will appear here.',
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
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadNotifications(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return NotificationItemCard(notification: list[index]);
                      },
                    ),
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
}
