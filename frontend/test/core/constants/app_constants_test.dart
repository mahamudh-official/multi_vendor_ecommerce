import 'package:flutter_test/flutter_test.dart';
import 'package:multi_vendor_ecommerce/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('apiBaseUrl returns a valid HTTP URL string', () {
      final url = AppConstants.apiBaseUrl;
      expect(url, isNotEmpty);
      expect(url.startsWith('http://') || url.startsWith('https://'), isTrue);
      expect(url.endsWith('/api/v1'), isTrue);
    });

    test('timeouts are correctly initialized and positive', () {
      expect(AppConstants.connectTimeout.inSeconds, equals(30));
      expect(AppConstants.receiveTimeout.inSeconds, equals(30));
      expect(AppConstants.sendTimeout.inSeconds, equals(30));
    });

    test('secure storage keys are properly defined', () {
      expect(AppConstants.accessTokenKey, equals('access_token'));
      expect(AppConstants.refreshTokenKey, equals('refresh_token'));
      expect(AppConstants.userIdKey, equals('user_id'));
      expect(AppConstants.userRoleKey, equals('user_role'));
    });

    test('pagination defaults and UI limits are properly set', () {
      expect(AppConstants.defaultPageSize, equals(20));
      expect(AppConstants.maxContentWidth, equals(600.0));
      expect(AppConstants.appName, equals('Marketo'));
    });
  });
}
