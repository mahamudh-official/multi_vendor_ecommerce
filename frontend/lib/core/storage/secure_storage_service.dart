import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../error/exceptions.dart';

/// Abstraction over [FlutterSecureStorage] for authentication token management.
///
/// No widget or BLoC should access secure storage directly.
/// All token operations must go through this service.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  // flutter_secure_storage v11 uses cipher algorithm options instead of
  // the deprecated encryptedSharedPreferences flag.
  static const _androidOptions = AndroidOptions(resetOnError: true);

  // ── Access Token ────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: token,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save access token: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(
        key: AppConstants.accessTokenKey,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to read access token: $e');
    }
  }

  // ── Refresh Token ───────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: token,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save refresh token: $e');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(
        key: AppConstants.refreshTokenKey,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to read refresh token: $e');
    }
  }

  // ── Composite operations ─────────────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Delete all authentication data (on logout or session expiry).
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(
          key: AppConstants.accessTokenKey,
          aOptions: _androidOptions,
        ),
        _storage.delete(
          key: AppConstants.refreshTokenKey,
          aOptions: _androidOptions,
        ),
        _storage.delete(key: AppConstants.userIdKey, aOptions: _androidOptions),
        _storage.delete(
          key: AppConstants.userRoleKey,
          aOptions: _androidOptions,
        ),
      ]);
    } catch (e) {
      throw CacheException(message: 'Failed to clear auth data: $e');
    }
  }

  /// Wipe the entire secure storage (use with caution).
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll(aOptions: _androidOptions);
    } catch (e) {
      throw CacheException(message: 'Failed to clear storage: $e');
    }
  }
}
