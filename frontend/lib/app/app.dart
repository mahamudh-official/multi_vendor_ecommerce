import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection_container.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/products/presentation/bloc/category/category_bloc.dart';
import '../features/products/presentation/bloc/product/product_bloc.dart';
import '../features/products/presentation/bloc/seller/seller_product_bloc.dart';

/// Root application widget.
///
/// Wires together:
/// - MultiBlocProvider (AuthBloc, CategoryBloc, ProductBloc, SellerProductBloc)
/// - go_router (declarative routing)
/// - Material 3 light / dark theme
class MarketoApp extends StatelessWidget {
  const MarketoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
        BlocProvider<CategoryBloc>(create: (_) => getIt<CategoryBloc>()),
        BlocProvider<ProductBloc>(create: (_) => getIt<ProductBloc>()),
        BlocProvider<SellerProductBloc>(create: (_) => getIt<SellerProductBloc>()),
      ],
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
