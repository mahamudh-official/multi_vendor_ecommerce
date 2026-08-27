import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/constants/app_constants.dart';
import 'package:multi_vendor_ecommerce/core/di/injection_container.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_theme.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:multi_vendor_ecommerce/features/splash/presentation/pages/splash_page.dart';

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
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SplashPage()),
          GoRoute(
            path: '/welcome',
            builder: (_, _) => const Scaffold(body: Text('Welcome')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>(),
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      // Pump to show initial frame (before navigation timer fires)
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);

      // Let the navigation timer complete to clean up
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
