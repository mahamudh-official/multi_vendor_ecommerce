/// Application-wide constants.
///
/// All magic values (timeouts, keys, etc.) must be centralized here.
abstract final class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────────────────
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator
  static const String apiBaseUrlLocal = 'http://localhost:8000/api/v1'; // iOS simulator / Web

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
