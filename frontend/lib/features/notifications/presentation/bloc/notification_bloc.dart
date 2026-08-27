import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/entities/app_notification.dart';
import 'package:multi_vendor_ecommerce/features/notifications/domain/usecases/notification_usecases.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationEvent {
  final bool unreadOnly;
  final bool refresh;

  const NotificationsRequested({this.unreadOnly = false, this.refresh = false});

  @override
  List<Object?> get props => [unreadOnly, refresh];
}

class UnreadCountRequested extends NotificationEvent {
  const UnreadCountRequested();
}

class NotificationReadMarked extends NotificationEvent {
  final String notificationId;

  const NotificationReadMarked({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class AllNotificationsReadMarked extends NotificationEvent {
  const AllNotificationsReadMarked();
}

class NotificationsReset extends NotificationEvent {
  const NotificationsReset();
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class NotificationState extends Equatable {
  final int unreadCount;

  const NotificationState({this.unreadCount = 0});

  @override
  List<Object?> get props => [unreadCount];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial({super.unreadCount = 0});
}

class NotificationLoading extends NotificationState {
  const NotificationLoading({super.unreadCount = 0});
}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final bool unreadOnly;

  const NotificationLoaded({
    required this.notifications,
    this.unreadOnly = false,
    required super.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadOnly, unreadCount];
}

class NotificationFailure extends NotificationState {
  final String message;

  const NotificationFailure({required this.message, super.unreadCount = 0});

  @override
  List<Object?> get props => [message, unreadCount];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadNotificationCountUseCase getUnreadCountUseCase;
  final MarkNotificationReadUseCase markReadUseCase;
  final MarkAllNotificationsReadUseCase markAllReadUseCase;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markReadUseCase,
    required this.markAllReadUseCase,
  }) : super(const NotificationInitial()) {
    on<NotificationsRequested>(_onNotificationsRequested);
    on<UnreadCountRequested>(_onUnreadCountRequested);
    on<NotificationReadMarked>(_onNotificationReadMarked);
    on<AllNotificationsReadMarked>(_onAllNotificationsReadMarked);
    on<NotificationsReset>(_onNotificationsReset);
  }

  Future<void> _onNotificationsRequested(
    NotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentUnread = state.unreadCount;
    emit(NotificationLoading(unreadCount: currentUnread));

    final countRes = await getUnreadCountUseCase();
    final updatedCount = countRes.fold(
      onSuccess: (count) => count,
      onError: (_) => currentUnread,
    );

    final result = await getNotificationsUseCase(unreadOnly: event.unreadOnly);

    result.fold(
      onSuccess: (notifications) => emit(
        NotificationLoaded(
          notifications: notifications,
          unreadOnly: event.unreadOnly,
          unreadCount: updatedCount,
        ),
      ),
      onError: (failure) => emit(
        NotificationFailure(
          message: failure.message,
          unreadCount: updatedCount,
        ),
      ),
    );
  }

  Future<void> _onUnreadCountRequested(
    UnreadCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await getUnreadCountUseCase();
    result.fold(
      onSuccess: (count) {
        if (state is NotificationLoaded) {
          final loaded = state as NotificationLoaded;
          emit(
            NotificationLoaded(
              notifications: loaded.notifications,
              unreadOnly: loaded.unreadOnly,
              unreadCount: count,
            ),
          );
        } else {
          emit(NotificationInitial(unreadCount: count));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _onNotificationReadMarked(
    NotificationReadMarked event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await markReadUseCase(event.notificationId);
    result.fold(
      onSuccess: (updated) {
        if (state is NotificationLoaded) {
          final loaded = state as NotificationLoaded;
          final updatedList = loaded.notifications.map((n) {
            return n.id == updated.id ? updated : n;
          }).toList();
          final newCount = (loaded.unreadCount > 0)
              ? loaded.unreadCount - 1
              : 0;
          emit(
            NotificationLoaded(
              notifications: updatedList,
              unreadOnly: loaded.unreadOnly,
              unreadCount: newCount,
            ),
          );
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _onAllNotificationsReadMarked(
    AllNotificationsReadMarked event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await markAllReadUseCase();
    result.fold(
      onSuccess: (_) {
        if (state is NotificationLoaded) {
          final loaded = state as NotificationLoaded;
          final updatedList = loaded.notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
          emit(
            NotificationLoaded(
              notifications: updatedList,
              unreadOnly: loaded.unreadOnly,
              unreadCount: 0,
            ),
          );
        } else {
          emit(const NotificationInitial(unreadCount: 0));
        }
      },
      onError: (_) {},
    );
  }

  void _onNotificationsReset(
    NotificationsReset event,
    Emitter<NotificationState> emit,
  ) {
    emit(const NotificationInitial(unreadCount: 0));
  }
}
