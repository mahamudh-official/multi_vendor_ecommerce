import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/entities/app_notification.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<AppNotification>>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.getNotifications(
        unreadOnly: unreadOnly,
        page: page,
        pageSize: pageSize,
      );
      return Success(result);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final count = await remoteDataSource.getUnreadCount();
      return Success(count);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AppNotification>> markAsRead({
    required String notificationId,
  }) async {
    try {
      final result = await remoteDataSource.markAsRead(
        notificationId: notificationId,
      );
      return Success(result);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> markAllAsRead() async {
    try {
      final count = await remoteDataSource.markAllAsRead();
      return Success(count);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
