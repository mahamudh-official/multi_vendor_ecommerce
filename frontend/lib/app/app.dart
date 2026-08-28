import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection_container.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/cart/presentation/bloc/cart_bloc.dart';
import '../features/cart/presentation/bloc/cart_event.dart';
import '../features/orders/presentation/bloc/order_bloc.dart';
import '../features/orders/presentation/bloc/order_event.dart';
import '../features/products/presentation/bloc/category/category_bloc.dart';
import '../features/products/presentation/bloc/product/product_bloc.dart';
import '../features/products/presentation/bloc/seller/seller_product_bloc.dart';
import '../features/payment/presentation/bloc/payment_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/admin/presentation/bloc/admin_blocs.dart';
import '../features/search/presentation/bloc/product_search_bloc.dart';
import '../features/reviews/presentation/bloc/my_reviews_bloc.dart';
import '../features/reviews/presentation/bloc/review_bloc.dart';
import '../features/seller/presentation/bloc/seller_dashboard/seller_dashboard_bloc.dart';
import '../features/seller/presentation/bloc/seller_orders/seller_orders_bloc.dart';
import '../features/seller/presentation/bloc/seller_products/seller_products_bloc.dart';
import '../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../features/wishlist/presentation/bloc/wishlist_event.dart';

/// Root application widget.
///
/// Wires together:
/// - MultiBlocProvider (Auth, Catalog, Cart, Wishlist, Order, Seller, Payment, Notification, Admin, Search, Review BLoCs)
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
        BlocProvider<SellerProductBloc>(
          create: (_) => getIt<SellerProductBloc>(),
        ),
        BlocProvider<CartBloc>(create: (_) => getIt<CartBloc>()),
        BlocProvider<WishlistBloc>(create: (_) => getIt<WishlistBloc>()),
        BlocProvider<OrderBloc>(create: (_) => getIt<OrderBloc>()),
        BlocProvider<ProductSearchBloc>(
          create: (_) => getIt<ProductSearchBloc>(),
        ),
        BlocProvider<ReviewBloc>(create: (_) => getIt<ReviewBloc>()),
        BlocProvider<MyReviewsBloc>(create: (_) => getIt<MyReviewsBloc>()),
        BlocProvider<SellerDashboardBloc>(
          create: (_) => getIt<SellerDashboardBloc>(),
        ),
        BlocProvider<SellerProductsBloc>(
          create: (_) => getIt<SellerProductsBloc>(),
        ),
        BlocProvider<SellerOrdersBloc>(
          create: (_) => getIt<SellerOrdersBloc>(),
        ),
        BlocProvider<PaymentBloc>(create: (_) => getIt<PaymentBloc>()),
        BlocProvider<NotificationBloc>(
          create: (_) =>
              getIt<NotificationBloc>()..add(const UnreadCountRequested()),
        ),
        BlocProvider<AdminDashboardBloc>(
          create: (_) => getIt<AdminDashboardBloc>(),
        ),
        BlocProvider<AdminUsersBloc>(create: (_) => getIt<AdminUsersBloc>()),
        BlocProvider<AdminSellersBloc>(
          create: (_) => getIt<AdminSellersBloc>(),
        ),
        BlocProvider<AdminProductsBloc>(
          create: (_) => getIt<AdminProductsBloc>(),
        ),
        BlocProvider<AdminCategoriesBloc>(
          create: (_) => getIt<AdminCategoriesBloc>(),
        ),
        BlocProvider<AdminOrdersBloc>(create: (_) => getIt<AdminOrdersBloc>()),
        BlocProvider<AdminPaymentsBloc>(
          create: (_) => getIt<AdminPaymentsBloc>(),
        ),
        BlocProvider<AdminAuditLogsBloc>(
          create: (_) => getIt<AdminAuditLogsBloc>(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.read<CartBloc>().add(const CartRequested());
            context.read<WishlistBloc>().add(const WishlistRequested());
            context.read<NotificationBloc>().add(const UnreadCountRequested());
          } else if (state is Unauthenticated) {
            context.read<CartBloc>().add(const CartReset());
            context.read<WishlistBloc>().add(const WishlistReset());
            context.read<OrderBloc>().add(const OrdersReset());
            context.read<SellerDashboardBloc>().add(
              const SellerDashboardReset(),
            );
            context.read<SellerProductsBloc>().add(const SellerProductsReset());
            context.read<SellerOrdersBloc>().add(const SellerOrdersReset());
            context.read<PaymentBloc>().add(const PaymentReset());
            context.read<NotificationBloc>().add(const NotificationsReset());
          }
        },
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
      ),
    );
  }
}
