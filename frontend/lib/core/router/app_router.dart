import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/orders/presentation/pages/checkout_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/seller/presentation/pages/create_product_page.dart';
import '../../features/seller/presentation/pages/edit_product_page.dart';
import '../../features/seller/presentation/pages/seller_dashboard_page.dart';
import '../../features/seller/presentation/pages/seller_order_details_page.dart';
import '../../features/seller/presentation/pages/seller_orders_page.dart';
import '../../features/seller/presentation/pages/seller_products_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';

/// Application route constants.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetails = '/orders/:id';
  static const String productDetails = '/products/:id';

  // Seller Portal Routes
  static const String seller = '/seller';
  static const String sellerProducts = '/seller/products';
  static const String sellerProductCreate = '/seller/products/create';
  static const String sellerProductEdit = '/seller/products/:id/edit';
  static const String sellerOrders = '/seller/orders';
  static const String sellerOrderDetails = '/seller/orders/:id';
}

/// Application router configuration using go_router.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
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

    // ── Welcome / Guest Preview ──────────────────────────────────────────
    GoRoute(
      path: AppRoutes.welcome,
      name: 'welcome',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomePage(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),

    // ── Login ────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Register ─────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Home ─────────────────────────────────────────────────────────────
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomePage(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // ── Shopping Cart ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.cart,
      name: 'cart',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CartPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Wishlist ─────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.wishlist,
      name: 'wishlist',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WishlistPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Checkout ─────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.checkout,
      name: 'checkout',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CheckoutPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Order History ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.orders,
      name: 'orders',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OrdersPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Order Details ────────────────────────────────────────────────────
    GoRoute(
      path: '/orders/:id',
      name: 'order-details',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: OrderDetailsPage(orderId: id),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Product Details ──────────────────────────────────────────────────
    GoRoute(
      path: '/products/:id',
      name: 'product-details',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: ProductDetailsPage(productId: id),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Seller Dashboard ─────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.seller,
      name: 'seller-dashboard',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SellerDashboardPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Seller Products List ─────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.sellerProducts,
      name: 'seller-products',
      pageBuilder: (context, state) {
        final lowStock = state.uri.queryParameters['low_stock'] == 'true';
        final isActiveStr = state.uri.queryParameters['is_active'];
        final isActive = isActiveStr != null ? isActiveStr == 'true' : null;

        return CustomTransitionPage(
          key: state.pageKey,
          child: SellerProductsPage(
            initialLowStock: lowStock ? true : null,
            initialIsActive: isActive,
          ),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Create Seller Product ────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.sellerProductCreate,
      name: 'seller-product-create',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CreateProductPage(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),

    // ── Edit Seller Product ──────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.sellerProductEdit,
      name: 'seller-product-edit',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: EditProductPage(productId: id),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Seller Orders List ───────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.sellerOrders,
      name: 'seller-orders',
      pageBuilder: (context, state) {
        final status = state.uri.queryParameters['status'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: SellerOrdersPage(initialStatus: status),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Seller Order Details ─────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.sellerOrderDetails,
      name: 'seller-order-details',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: SellerOrderDetailsPage(orderId: id),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),
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

Widget _slideRightTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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
            Text('Page Not Found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
