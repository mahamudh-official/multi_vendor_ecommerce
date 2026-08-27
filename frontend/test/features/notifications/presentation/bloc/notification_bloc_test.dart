import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/entities/app_notification.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:multi_vendor_ecommerce/features/notifications/presentation/bloc/notification_bloc.dart';

class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockGetUnreadNotificationCountUseCase extends Mock
    implements GetUnreadNotificationCountUseCase {}

class MockMarkNotificationReadUseCase extends Mock
    implements MarkNotificationReadUseCase {}

class MockMarkAllNotificationsReadUseCase extends Mock
    implements MarkAllNotificationsReadUseCase {}

void main() {
  late NotificationBloc notificationBloc;
  late MockGetNotificationsUseCase mockGetNotificationsUseCase;
  late MockGetUnreadNotificationCountUseCase mockGetUnreadCountUseCase;
  late MockMarkNotificationReadUseCase mockMarkReadUseCase;
  late MockMarkAllNotificationsReadUseCase mockMarkAllReadUseCase;

  final tNotification = AppNotification(
    id: 'notif-1',
    userId: 'user-1',
    type: NotificationType.orderCreated,
    title: 'Order Placed',
    message: 'Your order was placed.',
    isRead: false,
    createdAt: DateTime.parse('2026-08-28T00:00:00Z'),
  );

  setUp(() {
    mockGetNotificationsUseCase = MockGetNotificationsUseCase();
    mockGetUnreadCountUseCase = MockGetUnreadNotificationCountUseCase();
    mockMarkReadUseCase = MockMarkNotificationReadUseCase();
    mockMarkAllReadUseCase = MockMarkAllNotificationsReadUseCase();

    notificationBloc = NotificationBloc(
      getNotificationsUseCase: mockGetNotificationsUseCase,
      getUnreadCountUseCase: mockGetUnreadCountUseCase,
      markReadUseCase: mockMarkReadUseCase,
      markAllReadUseCase: mockMarkAllReadUseCase,
    );
  });

  tearDown(() {
    notificationBloc.close();
  });

  test('initial state should have 0 unreadCount', () {
    expect(notificationBloc.state.unreadCount, 0);
  });

  group('NotificationsRequested', () {
    test(
      'emits [NotificationLoading, NotificationLoaded] on success',
      () async {
        when(
          () => mockGetUnreadCountUseCase(),
        ).thenAnswer((_) async => const Success(1));
        when(
          () => mockGetNotificationsUseCase(unreadOnly: false),
        ).thenAnswer((_) async => Success([tNotification]));

        final expected = [
          const NotificationLoading(unreadCount: 0),
          NotificationLoaded(
            notifications: [tNotification],
            unreadOnly: false,
            unreadCount: 1,
          ),
        ];

        expectLater(notificationBloc.stream, emitsInOrder(expected));
        notificationBloc.add(const NotificationsRequested(unreadOnly: false));
      },
    );

    test(
      'emits [NotificationLoading, NotificationFailure] on failure',
      () async {
        when(
          () => mockGetUnreadCountUseCase(),
        ).thenAnswer((_) async => const Success(0));
        when(() => mockGetNotificationsUseCase(unreadOnly: false)).thenAnswer(
          (_) async => const Error(ServerFailure(message: 'Server error')),
        );

        final expected = [
          const NotificationLoading(unreadCount: 0),
          const NotificationFailure(message: 'Server error', unreadCount: 0),
        ];

        expectLater(notificationBloc.stream, emitsInOrder(expected));
        notificationBloc.add(const NotificationsRequested(unreadOnly: false));
      },
    );
  });

  group('NotificationReadMarked', () {
    test('marks notification as read and decrements unread count', () async {
      when(
        () => mockGetUnreadCountUseCase(),
      ).thenAnswer((_) async => const Success(1));
      when(
        () => mockGetNotificationsUseCase(unreadOnly: false),
      ).thenAnswer((_) async => Success([tNotification]));
      when(
        () => mockMarkReadUseCase('notif-1'),
      ).thenAnswer((_) async => Success(tNotification.copyWith(isRead: true)));

      notificationBloc.add(const NotificationsRequested(unreadOnly: false));
      await untilCalled(() => mockGetNotificationsUseCase(unreadOnly: false));

      notificationBloc.add(
        const NotificationReadMarked(notificationId: 'notif-1'),
      );

      await expectLater(
        notificationBloc.stream,
        emitsThrough(
          predicate<NotificationState>((state) {
            if (state is NotificationLoaded) {
              return state.notifications.first.isRead == true &&
                  state.unreadCount == 0;
            }
            return false;
          }),
        ),
      );
    });
  });

  group('AllNotificationsReadMarked', () {
    test(
      'marks all notifications as read and resets unread count to 0',
      () async {
        when(
          () => mockGetUnreadCountUseCase(),
        ).thenAnswer((_) async => const Success(1));
        when(
          () => mockGetNotificationsUseCase(unreadOnly: false),
        ).thenAnswer((_) async => Success([tNotification]));
        when(
          () => mockMarkAllReadUseCase(),
        ).thenAnswer((_) async => const Success(1));

        notificationBloc.add(const NotificationsRequested(unreadOnly: false));
        await untilCalled(() => mockGetNotificationsUseCase(unreadOnly: false));

        notificationBloc.add(const AllNotificationsReadMarked());

        await expectLater(
          notificationBloc.stream,
          emitsThrough(
            predicate<NotificationState>((state) {
              if (state is NotificationLoaded) {
                return state.notifications.every((n) => n.isRead) &&
                    state.unreadCount == 0;
              }
              return false;
            }),
          ),
        );
      },
    );
  });
}
