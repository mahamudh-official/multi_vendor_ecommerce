import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/di/injection_container.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_theme.dart';
import 'package:multi_vendor_ecommerce/core/constants/app_constants.dart';
import 'package:multi_vendor_ecommerce/features/splash/presentation/pages/splash_page.dart';

/// Step 1 smoke tests.
///
/// All theme and constants tests run without the full router to avoid
/// navigation-related side effects in tests.
void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  group('AppTheme', () {
    testWidgets('light theme renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Center(child: Text('Test'))),
        ),
      );
      final theme = Theme.of(tester.element(find.text('Test')));
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('dark theme renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: Center(child: Text('Test'))),
        ),
      );
      final theme = Theme.of(tester.element(find.text('Test')));
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('AppConstants', () {
    test('app name is not empty', () {
      expect(AppConstants.appName, isNotEmpty);
    });

    test('api base url is not empty', () {
      expect(AppConstants.apiBaseUrl, isNotEmpty);
    });

    test('connect timeout is positive', () {
      expect(AppConstants.connectTimeout.inSeconds, greaterThan(0));
    });
  });

  group('SplashPage', () {
    testWidgets('renders logo and app name before navigation fires', (
      tester,
    ) async {
      // Wrap SplashPage with a GoRouter so context.go() works
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SplashPage()),
          GoRoute(
            path: '/welcome',
            builder: (_, _) => const Scaffold(body: Text('Welcome')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );

      // Pump to show initial frame (before 1800ms timer fires)
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);

      // Let the navigation timer complete to clean up
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
