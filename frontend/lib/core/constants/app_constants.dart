import 'package:flutter/foundation.dart';

/// Application-wide constants.
///
/// All magic values (timeouts, keys, etc.) must be centralized here.
abstract final class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────────────────
  /// Dynamic API Base URL resolution:
  /// 1. If `--dart-define=API_BASE_URL=...` is passed at build/runtime, use it.
  /// 2. If running on Web, default to `http://localhost:8000/api/v1`.
  /// 3. If running on Android emulator/device, default to `http://10.0.2.2:8000/api/v1`.
  /// 4. Otherwise (iOS Simulator, macOS, Windows, Linux), default to `http://localhost:8000/api/v1`.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static const String apiBaseUrlLocal = 'http://localhost:8000/api/v1';

  // ── Timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Secure Storage Keys ────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';

  // ── Pagination ────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── UI ─────────────────────────────────────────────────────────────────
  static const double maxContentWidth = 600; // Max width for content on wide screens
  static const String appName = 'Marketo';
  static const String appTagline = 'Shop from trusted sellers';
}
