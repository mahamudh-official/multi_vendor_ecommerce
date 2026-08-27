import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/entities/app_notification.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<Result<List<AppNotification>>> call({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getNotifications(
      unreadOnly: unreadOnly,
      page: page,
      pageSize: pageSize,
    );
  }
}

class GetUnreadNotificationCountUseCase {
  final NotificationRepository repository;

  GetUnreadNotificationCountUseCase(this.repository);

  Future<Result<int>> call() {
    return repository.getUnreadCount();
  }
}

class MarkNotificationReadUseCase {
  final NotificationRepository repository;

  MarkNotificationReadUseCase(this.repository);

  Future<Result<AppNotification>> call(String notificationId) {
    return repository.markAsRead(notificationId: notificationId);
  }
}

class MarkAllNotificationsReadUseCase {
  final NotificationRepository repository;

  MarkAllNotificationsReadUseCase(this.repository);

  Future<Result<int>> call() {
    return repository.markAllAsRead();
  }
}
