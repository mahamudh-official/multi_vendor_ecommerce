import '../../../../core/error/result.dart';
import '../entities/auth_user.dart';

/// Abstract repository contract for authentication operations.
abstract interface class AuthRepository {
  /// Register a new customer or seller account.
  Future<Result<AuthUser>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  });

  /// Authenticate credentials and persist session tokens.
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  /// Fetch profile of currently authenticated user.
  Future<Result<AuthUser>> getCurrentUser();

  /// Exchange refresh token for a new access token.
  Future<Result<void>> refreshToken();

  /// Log out and wipe local tokens.
  Future<Result<void>> logout();

  /// Check if a valid session exists in secure storage.
  Future<bool> isAuthenticated();
}
