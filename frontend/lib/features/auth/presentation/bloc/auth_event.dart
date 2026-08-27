import 'package:equatable/equatable.dart';

/// Base class for all authentication BLoC events.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check stored session on application launch or resume.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User submitted the login form.
final class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// User submitted the registration form.
final class RegisterSubmitted extends AuthEvent {
  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String fullName;
  final String email;
  final String password;
  final String role;

  @override
  List<Object?> get props => [fullName, email, password, role];
}

/// User triggered session logout.
final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Silent background token refresh requested.
final class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();
}
