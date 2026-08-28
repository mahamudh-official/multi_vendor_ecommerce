import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/orders/presentation/pages/checkout_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/payment/domain/entities/payment.dart';
import '../../features/payment/presentation/pages/payment_failure_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/payment/presentation/pages/payment_success_page.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/reviews/presentation/pages/my_reviews_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/seller/presentation/pages/create_product_page.dart';
import '../../features/seller/presentation/pages/edit_product_page.dart';
import '../../features/seller/presentation/pages/seller_dashboard_page.dart';
import '../../features/seller/presentation/pages/seller_order_details_page.dart';
import '../../features/seller/presentation/pages/seller_orders_page.dart';
import '../../features/seller/presentation/pages/seller_products_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_sellers_page.dart';
import '../../features/admin/presentation/pages/admin_products_page.dart';
import '../../features/admin/presentation/pages/admin_categories_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../features/admin/presentation/pages/admin_order_details_page.dart';
import '../../features/admin/presentation/pages/admin_payments_page.dart';
import '../../features/admin/presentation/pages/admin_audit_logs_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/addresses/domain/entities/address.dart';
import '../../features/addresses/presentation/pages/address_list_page.dart';
import '../../features/addresses/presentation/pages/add_edit_address_page.dart';
import '../../features/seller_analytics/presentation/pages/seller_analytics_page.dart';
import 'dart:async';
import '../di/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// Application route constants.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String home = '/home';
  static const String search = '/search';
  static const String myReviews = '/my-reviews';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetails = '/orders/:id';
  static const String productDetails = '/products/:id';

  // Customer Profile & Address Routes
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String addresses = '/addresses';
  static const String addressAdd = '/addresses/add';
  static const String addressEdit = '/addresses/:id/edit';

  // Seller Analytics Route
  static const String sellerAnalytics = '/seller/analytics';

  // Notifications Route
  static const String notifications = '/notifications';

  // Payment Routes
  static const String payment = '/payment/:orderId';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailure = '/payment/failure';

  // Seller Portal Routes
  static const String seller = '/seller';
  static const String sellerProducts = '/seller/products';
  static const String sellerProductCreate = '/seller/products/create';
  static const String sellerProductEdit = '/seller/products/:id/edit';
  static const String sellerOrders = '/seller/orders';
  static const String sellerOrderDetails = '/seller/orders/:id';

  // Admin Portal Routes
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminSellers = '/admin/sellers';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetails = '/admin/orders/:id';
  static const String adminPayments = '/admin/payments';
  static const String adminAuditLogs = '/admin/audit-logs';
}

class RouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  StreamSubscription<AuthState>? _subscription;

  RouterNotifier(this._authBloc) {
    _subscription = _authBloc.stream.listen((state) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Application router configuration using go_router.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  refreshListenable: RouterNotifier(getIt<AuthBloc>()),
  redirect: (context, state) {
    final authState = getIt<AuthBloc>().state;
    final loc = state.matchedLocation;

    final isAuthenticated = authState is Authenticated;

    final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;
    final isSplashRoute = loc == AppRoutes.splash;
    final isWelcomeRoute = loc == AppRoutes.welcome;

    final isPublicRoute =
        isSplashRoute ||
        isWelcomeRoute ||
        isAuthRoute ||
        loc == AppRoutes.home ||
        loc == AppRoutes.search ||
        loc.startsWith('/products/');

    final isSellerRoute = loc.startsWith('/seller');
    final isAdminRoute = loc.startsWith('/admin');

    if (authState is AuthInitial || authState is AuthLoading) {
      return null;
    }

    if (!isAuthenticated && !isPublicRoute) {
      return AppRoutes.login;
    }

    if (isAuthenticated) {
      final user = authState.user;

      if (isAuthRoute || isSplashRoute) {
        return AppRoutes.home;
      }

      if (user.isCustomer) {
        if (isSellerRoute || isAdminRoute) {
          return AppRoutes.home;
        }
      }

      if (user.isSeller) {
        if (isAdminRoute) {
          return AppRoutes.home;
        }
      }

      if (user.isAdmin) {
        if (isSellerRoute) {
          return AppRoutes.home;
        }
      }
    }

    return null;
  },
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

    // ── Search & Filter ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.search,
      name: 'search',
      pageBuilder: (context, state) {
        final query = state.uri.queryParameters['q'];
        final categoryId = state.uri.queryParameters['category_id'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: SearchPage(initialQuery: query, initialCategoryId: categoryId),
          transitionsBuilder: _fadeTransition,
        );
      },
    ),

    // ── My Reviews ───────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.myReviews,
      name: 'my-reviews',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MyReviewsPage(),
        transitionsBuilder: _slideRightTransition,
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

    // ── Notifications ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationsPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Payment ──────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.payment,
      name: 'payment',
      pageBuilder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: PaymentPage(orderId: orderId),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Payment Success ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.paymentSuccess,
      name: 'payment-success',
      pageBuilder: (context, state) {
        final result = state.extra as PaymentProcessResult?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PaymentSuccessPage(result: result),
          transitionsBuilder: _fadeTransition,
        );
      },
    ),

    // ── Payment Failure ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.paymentFailure,
      name: 'payment-failure',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PaymentFailurePage(
            message:
                extra?['message'] as String? ??
                'Payment could not be processed.',
            paymentId: extra?['paymentId'] as String?,
            orderId: extra?['orderId'] as String?,
          ),
          transitionsBuilder: _fadeTransition,
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

    // ── Admin Dashboard ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.admin,
      name: 'admin-dashboard',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminDashboardPage(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // ── Admin Users ──────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminUsers,
      name: 'admin-users',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminUsersPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Admin Sellers ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminSellers,
      name: 'admin-sellers',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminSellersPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Admin Products ───────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminProducts,
      name: 'admin-products',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminProductsPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Admin Categories ─────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminCategories,
      name: 'admin-categories',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminCategoriesPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Admin Orders ─────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminOrders,
      name: 'admin-orders',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminOrdersPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Admin Order Details ──────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminOrderDetails,
      name: 'admin-order-details',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: AdminOrderDetailsPage(orderId: id),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Admin Payments ───────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminPayments,
      name: 'admin-payments',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminPaymentsPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Admin Audit Logs ─────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminAuditLogs,
      name: 'admin-audit-logs',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminAuditLogsPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Customer Profile ────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProfilePage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Edit Customer Profile ────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.profileEdit,
      name: 'profile-edit',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EditProfilePage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Saved Delivery Addresses ─────────────────────────────────────────
    GoRoute(
      path: AppRoutes.addresses,
      name: 'addresses',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddressListPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Add Address ──────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.addressAdd,
      name: 'address-add',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddEditAddressPage(),
        transitionsBuilder: _slideRightTransition,
      ),
    ),

    // ── Edit Address ─────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.addressEdit,
      name: 'address-edit',
      pageBuilder: (context, state) {
        final existingAddress = state.extra as Address?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: AddEditAddressPage(existingAddress: existingAddress),
          transitionsBuilder: _slideRightTransition,
        );
      },
    ),

    // ── Seller Analytics ─────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.sellerAnalytics,
      name: 'seller-analytics',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SellerAnalyticsPage(),
        transitionsBuilder: _slideRightTransition,
      ),
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
