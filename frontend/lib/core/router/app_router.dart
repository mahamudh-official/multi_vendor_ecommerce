import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

/// Application route names — use these constants instead of raw strings.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';

  // ── Step 2+ ─────────────────────────────────────────────────────────────
  // static const String login = '/auth/login';
  // static const String register = '/auth/register';
  // static const String home = '/home';
  // static const String products = '/products';
  // static const String productDetail = '/products/:id';
  // static const String cart = '/cart';
  // static const String orders = '/orders';
  // static const String seller = '/seller';
  // static const String admin = '/admin';
}

/// Application router configuration using go_router.
///
/// Structure:
///   / (splash) → /welcome (home preview)
///
/// Future routes will be added here without touching existing routes.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,

  routes: [
    // ── Splash ──────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashPage(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // ── Welcome / Home Preview ───────────────────────────────────────────
    GoRoute(
      path: AppRoutes.welcome,
      name: 'welcome',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomePage(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),

    // ── Step 2+ routes will be added below ───────────────────────────────
  ],

  // Global error page
  errorPageBuilder: (context, state) => MaterialPage(
    child: _ErrorPage(error: state.error?.message ?? 'Page not found'),
  ),
);

// ── Transitions ─────────────────────────────────────────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
    child: FadeTransition(opacity: animation, child: child),
  );
}

// ── Error Page ───────────────────────────────────────────────────────────────

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
