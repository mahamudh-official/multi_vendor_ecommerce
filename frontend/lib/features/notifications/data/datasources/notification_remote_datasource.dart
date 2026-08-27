import 'package:multi_vendor_ecommerce/core/network/dio_client.dart';
import 'package:multi_vendor_ecommerce/features/notifications/data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AppNotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<int> getUnreadCount();

  Future<AppNotificationModel> markAsRead({required String notificationId});

  Future<int> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final DioClient dioClient;

  NotificationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<AppNotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dioClient.get(
      '/notifications',
      queryParameters: {
        'unread_only': unreadOnly,
        'page': page,
        'page_size': pageSize,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((i) => AppNotificationModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await dioClient.get('/notifications/unread-count');
    final data = response.data as Map<String, dynamic>;
    return data['unread_count'] as int? ?? 0;
  }

  @override
  Future<AppNotificationModel> markAsRead({
    required String notificationId,
  }) async {
    final response = await dioClient.post(
      '/notifications/$notificationId/read',
    );
    return AppNotificationModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await dioClient.post('/notifications/read-all');
    final data = response.data as Map<String, dynamic>;
    return data['marked_read_count'] as int? ?? 0;
  }
}
