import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC managing application-wide authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.checkAuthStatusUseCase,
    required this.getCurrentUserUseCase,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.refreshTokenUseCase,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
  }

  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking session…'));
    final hasToken = await checkAuthStatusUseCase();
    if (!hasToken) {
      emit(const Unauthenticated());
      return;
    }

    final result = await getCurrentUserUseCase();
    result.fold(
      onSuccess: (user) => emit(Authenticated(user: user)),
      onError: (_) => emit(const Unauthenticated()),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in…'));
    final result = await loginUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      onSuccess: (user) => emit(Authenticated(user: user)),
      onError: (failure) => emit(AuthFailure(message: failure.message)),
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account…'));
    final registerResult = await registerUseCase(
      fullName: event.fullName,
      email: event.email,
      password: event.password,
      role: event.role,
    );

    await registerResult.fold(
      onSuccess: (registeredUser) async {
        // Automatically log in upon successful registration for a seamless UX
        final loginResult = await loginUseCase(
          email: event.email,
          password: event.password,
        );
        loginResult.fold(
          onSuccess: (user) => emit(Authenticated(user: user)),
          onError: (_) => emit(Authenticated(user: registeredUser)),
        );
      },
      onError: (failure) async => emit(AuthFailure(message: failure.message)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out…'));
    await logoutUseCase();
    emit(const Unauthenticated());
  }

  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await refreshTokenUseCase();
    if (result.isError) {
      emit(const Unauthenticated());
    }
  }
}
