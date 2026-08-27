import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/auth/domain/entities/auth_user.dart';
import 'package:multi_vendor_ecommerce/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:multi_vendor_ecommerce/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:multi_vendor_ecommerce/features/auth/domain/usecases/login_usecase.dart';
import 'package:multi_vendor_ecommerce/features/auth/domain/usecases/logout_usecase.dart';
import 'package:multi_vendor_ecommerce/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:multi_vendor_ecommerce/features/auth/domain/usecases/register_usecase.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_event.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_state.dart';

class MockCheckAuthStatusUseCase extends Mock
    implements CheckAuthStatusUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

void main() {
  late MockCheckAuthStatusUseCase mockCheckAuthStatusUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockRefreshTokenUseCase mockRefreshTokenUseCase;
  late AuthBloc authBloc;

  final testUser = AuthUser(
    id: 'user-uuid-1234',
    email: 'test@example.com',
    fullName: 'Test User',
    role: 'customer',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockCheckAuthStatusUseCase = MockCheckAuthStatusUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockRefreshTokenUseCase = MockRefreshTokenUseCase();

    authBloc = AuthBloc(
      checkAuthStatusUseCase: mockCheckAuthStatusUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      logoutUseCase: mockLogoutUseCase,
      refreshTokenUseCase: mockRefreshTokenUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state should be AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when valid token and user profile exist',
        build: () {
          when(
            () => mockCheckAuthStatusUseCase(),
          ).thenAnswer((_) async => true);
          when(
            () => mockGetCurrentUserUseCase(),
          ).thenAnswer((_) async => Success(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(message: 'Checking session…'),
          Authenticated(user: testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] when no stored token exists',
        build: () {
          when(
            () => mockCheckAuthStatusUseCase(),
          ).thenAnswer((_) async => false);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(message: 'Checking session…'),
          const Unauthenticated(),
        ],
      );
    });

    group('LoginSubmitted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] on successful login credentials',
        build: () {
          when(
            () => mockLoginUseCase(
              email: 'test@example.com',
              password: 'Password123!',
            ),
          ).thenAnswer((_) async => Success(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginSubmitted(
            email: 'test@example.com',
            password: 'Password123!',
          ),
        ),
        expect: () => [
          const AuthLoading(message: 'Signing in…'),
          Authenticated(user: testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] on invalid credentials',
        build: () {
          when(
            () => mockLoginUseCase(
              email: 'test@example.com',
              password: 'WrongPassword',
            ),
          ).thenAnswer(
            (_) async => const Error(
              UnauthorizedFailure(message: 'Invalid email or password.'),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginSubmitted(
            email: 'test@example.com',
            password: 'WrongPassword',
          ),
        ),
        expect: () => [
          const AuthLoading(message: 'Signing in…'),
          const AuthFailure(message: 'Invalid email or password.'),
        ],
      );
    });

    group('RegisterSubmitted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] on successful registration and auto-login',
        build: () {
          when(
            () => mockRegisterUseCase(
              fullName: 'Test User',
              email: 'test@example.com',
              password: 'Password123!',
              role: 'customer',
            ),
          ).thenAnswer((_) async => Success(testUser));
          when(
            () => mockLoginUseCase(
              email: 'test@example.com',
              password: 'Password123!',
            ),
          ).thenAnswer((_) async => Success(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterSubmitted(
            fullName: 'Test User',
            email: 'test@example.com',
            password: 'Password123!',
            role: 'customer',
          ),
        ),
        expect: () => [
          const AuthLoading(message: 'Creating account…'),
          Authenticated(user: testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when email already exists',
        build: () {
          when(
            () => mockRegisterUseCase(
              fullName: 'Test User',
              email: 'duplicate@example.com',
              password: 'Password123!',
              role: 'customer',
            ),
          ).thenAnswer(
            (_) async => const Error(
              ConflictFailure(
                message: 'An account with this email already exists.',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterSubmitted(
            fullName: 'Test User',
            email: 'duplicate@example.com',
            password: 'Password123!',
            role: 'customer',
          ),
        ),
        expect: () => [
          const AuthLoading(message: 'Creating account…'),
          const AuthFailure(
            message: 'An account with this email already exists.',
          ),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] when user logs out',
        build: () {
          when(
            () => mockLogoutUseCase(),
          ).thenAnswer((_) async => const Success(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [
          const AuthLoading(message: 'Signing out…'),
          const Unauthenticated(),
        ],
      );
    });
  });
}
