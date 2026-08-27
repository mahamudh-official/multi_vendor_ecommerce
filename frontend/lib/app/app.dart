import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

/// Root application widget.
///
/// Wires together:
/// - go_router (declarative routing)
/// - Material 3 light / dark theme
/// - BlocObserver (Step 2 will add global BLoC logging)
class MarketoApp extends StatelessWidget {
  const MarketoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Marketo',
      debugShowCheckedModeBanner: false,

      // ── Routing ──────────────────────────────────────────────────────────
      routerConfig: appRouter,

      // ── Theming ──────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // Respect OS preference

      // ── Localization (Step N will add intl support) ───────────────────────
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
