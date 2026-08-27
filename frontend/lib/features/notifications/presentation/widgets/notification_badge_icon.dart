import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/features/notifications/presentation/bloc/notification_bloc.dart';

class NotificationBadgeIcon extends StatelessWidget {
  final Color? color;

  const NotificationBadgeIcon({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final count = state.unreadCount;
        final countText = count > 99 ? '99+' : count.toString();

        return IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              countText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColorsLight.error,
            child: Icon(Icons.notifications_outlined, color: color),
          ),
          tooltip: 'Notifications ($count unread)',
          onPressed: () => context.push('/notifications'),
        );
      },
    );
  }
}
