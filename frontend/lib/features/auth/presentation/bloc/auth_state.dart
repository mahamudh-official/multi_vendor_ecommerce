import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';

/// Base class for all authentication BLoC states.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// In-progress asynchronous operation (login, register, session check).
final class AuthLoading extends AuthState {
  const AuthLoading({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// User is successfully authenticated with a valid session.
final class Authenticated extends AuthState {
  const Authenticated({required this.user});

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated (guest).
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication operation failed with an error message.
final class AuthFailure extends AuthState {
  const AuthFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
