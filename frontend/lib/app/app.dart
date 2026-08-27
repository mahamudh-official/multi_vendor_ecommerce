import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection_container.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Root application widget.
///
/// Wires together:
/// - AuthBloc (global authentication provider)
/// - go_router (declarative routing)
/// - Material 3 light / dark theme
class MarketoApp extends StatelessWidget {
  const MarketoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Marketo',
        debugShowCheckedModeBanner: false,

        // ── Routing ────────────────────────────────────────────────────────
        routerConfig: appRouter,

        // ── Theming ────────────────────────────────────────────────────────
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
      ),
    );
  }
}
