import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Result<List<AppNotification>>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<int>> getUnreadCount();

  Future<Result<AppNotification>> markAsRead({required String notificationId});

  Future<Result<int>> markAllAsRead();
}
