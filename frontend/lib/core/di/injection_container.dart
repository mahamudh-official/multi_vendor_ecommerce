import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/cart/data/datasources/cart_remote_datasource.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/add_to_cart_usecase.dart';
import '../../features/cart/domain/usecases/clear_cart_usecase.dart';
import '../../features/cart/domain/usecases/get_cart_usecase.dart';
import '../../features/cart/domain/usecases/remove_cart_item_usecase.dart';
import '../../features/cart/domain/usecases/update_cart_item_usecase.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/orders/data/datasources/order_remote_datasource.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/usecases/cancel_order_usecase.dart';
import '../../features/orders/domain/usecases/checkout_usecase.dart';
import '../../features/orders/domain/usecases/get_order_details_usecase.dart';
import '../../features/orders/domain/usecases/get_orders_usecase.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';
import '../../features/products/data/datasources/category_remote_datasource.dart';
import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/repositories/category_repository_impl.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/category_repository.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/create_product_usecase.dart';
import '../../features/products/domain/usecases/delete_product_usecase.dart';
import '../../features/products/domain/usecases/get_categories_usecase.dart';
import '../../features/products/domain/usecases/get_product_details_usecase.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart';
import '../../features/products/domain/usecases/update_product_usecase.dart';
import '../../features/products/presentation/bloc/category/category_bloc.dart';
import '../../features/products/presentation/bloc/product/product_bloc.dart';
import '../../features/products/presentation/bloc/seller/seller_product_bloc.dart';
import '../../features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import '../../features/wishlist/data/repositories/wishlist_repository_impl.dart';
import '../../features/wishlist/domain/repositories/wishlist_repository.dart';
import '../../features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import '../../features/wishlist/domain/usecases/clear_wishlist_usecase.dart';
import '../../features/wishlist/domain/usecases/get_wishlist_usecase.dart';
import '../../features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../features/seller/data/datasources/seller_remote_datasource.dart';
import '../../features/seller/data/repositories/seller_repository_impl.dart';
import '../../features/seller/domain/repositories/seller_repository.dart';
import '../../features/seller/domain/usecases/get_seller_dashboard_usecase.dart';
import '../../features/seller/domain/usecases/seller_product_usecases.dart';
import '../../features/seller/domain/usecases/seller_order_usecases.dart';
import '../../features/seller/presentation/bloc/seller_dashboard/seller_dashboard_bloc.dart';
import '../../features/seller/presentation/bloc/seller_products/seller_products_bloc.dart';
import '../../features/seller/presentation/bloc/seller_orders/seller_orders_bloc.dart';

final getIt = GetIt.instance;

/// Initialize all service locator registrations.
Future<void> configureDependencies() async {
  // ── Core / Infrastructure ──────────────────────────────────────────────────
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt<FlutterSecureStorage>()),
  );

  getIt.registerLazySingleton<DioClient>(() => DioClient());

  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      secureStorage: getIt<SecureStorageService>(),
      dio: getIt<DioClient>().client,
    ),
  );

  // Attach auth interceptor to DioClient
  getIt<DioClient>().addInterceptor(getIt<AuthInterceptor>());

  // ── Feature: Auth Data Layer ───────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      secureStorage: getIt<SecureStorageService>(),
      dioClient: getIt<DioClient>(),
    ),
  );

  // ── Feature: Auth Domain Layer (Use Cases) ─────────────────────────────────
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RefreshTokenUseCase>(
    () => RefreshTokenUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<CheckAuthStatusUseCase>(
    () => CheckAuthStatusUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      checkAuthStatusUseCase: getIt<CheckAuthStatusUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      refreshTokenUseCase: getIt<RefreshTokenUseCase>(),
    ),
  );

  // ── Features: Category & Product Data Layer ──────────────────────────────
  getIt.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt<CategoryRemoteDataSource>()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt<ProductRemoteDataSource>()),
  );

  // ── Features: Category & Product Domain Layer (Use Cases) ────────────────
  getIt.registerLazySingleton<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton<GetProductsUseCase>(
    () => GetProductsUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton<GetProductDetailsUseCase>(
    () => GetProductDetailsUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton<CreateProductUseCase>(
    () => CreateProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton<UpdateProductUseCase>(
    () => UpdateProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton<DeleteProductUseCase>(
    () => DeleteProductUseCase(getIt<ProductRepository>()),
  );

  // ── Features: Category & Product Presentation (BLoCs) ────────────────────
  getIt.registerFactory<CategoryBloc>(
    () => CategoryBloc(getCategoriesUseCase: getIt<GetCategoriesUseCase>()),
  );

  getIt.registerFactory<ProductBloc>(
    () => ProductBloc(getProductsUseCase: getIt<GetProductsUseCase>()),
  );

  getIt.registerFactory<SellerProductBloc>(
    () => SellerProductBloc(
      getProductsUseCase: getIt<GetProductsUseCase>(),
      createProductUseCase: getIt<CreateProductUseCase>(),
      updateProductUseCase: getIt<UpdateProductUseCase>(),
      deleteProductUseCase: getIt<DeleteProductUseCase>(),
    ),
  );

  // ── Features: Cart & Wishlist Data Layer ─────────────────────────────────
  getIt.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(dioClient: getIt<DioClient>()),
  );
  getIt.registerLazySingleton<WishlistRemoteDataSource>(
    () => WishlistRemoteDataSourceImpl(dioClient: getIt<DioClient>()),
  );

  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(remoteDataSource: getIt<CartRemoteDataSource>()),
  );
  getIt.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(
      remoteDataSource: getIt<WishlistRemoteDataSource>(),
    ),
  );

  // ── Features: Cart & Wishlist Domain Layer (Use Cases) ───────────────────
  getIt.registerLazySingleton<GetCartUseCase>(
    () => GetCartUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<AddToCartUseCase>(
    () => AddToCartUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<UpdateCartItemUseCase>(
    () => UpdateCartItemUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<RemoveCartItemUseCase>(
    () => RemoveCartItemUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<ClearCartUseCase>(
    () => ClearCartUseCase(getIt<CartRepository>()),
  );

  getIt.registerLazySingleton<GetWishlistUseCase>(
    () => GetWishlistUseCase(getIt<WishlistRepository>()),
  );
  getIt.registerLazySingleton<AddToWishlistUseCase>(
    () => AddToWishlistUseCase(getIt<WishlistRepository>()),
  );
  getIt.registerLazySingleton<RemoveFromWishlistUseCase>(
    () => RemoveFromWishlistUseCase(getIt<WishlistRepository>()),
  );
  getIt.registerLazySingleton<ClearWishlistUseCase>(
    () => ClearWishlistUseCase(getIt<WishlistRepository>()),
  );

  // ── Features: Cart & Wishlist Presentation (BLoCs) ───────────────────────
  getIt.registerLazySingleton<CartBloc>(
    () => CartBloc(
      getCartUseCase: getIt<GetCartUseCase>(),
      addToCartUseCase: getIt<AddToCartUseCase>(),
      updateCartItemUseCase: getIt<UpdateCartItemUseCase>(),
      removeCartItemUseCase: getIt<RemoveCartItemUseCase>(),
      clearCartUseCase: getIt<ClearCartUseCase>(),
    ),
  );

  getIt.registerLazySingleton<WishlistBloc>(
    () => WishlistBloc(
      getWishlistUseCase: getIt<GetWishlistUseCase>(),
      addToWishlistUseCase: getIt<AddToWishlistUseCase>(),
      removeFromWishlistUseCase: getIt<RemoveFromWishlistUseCase>(),
      clearWishlistUseCase: getIt<ClearWishlistUseCase>(),
    ),
  );

  // ── Features: Orders Data Layer ──────────────────────────────────────────
  getIt.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(dioClient: getIt<DioClient>()),
  );

  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: getIt<OrderRemoteDataSource>()),
  );

  // ── Features: Orders Domain Layer (Use Cases) ────────────────────────────
  getIt.registerLazySingleton<CheckoutUseCase>(
    () => CheckoutUseCase(getIt<OrderRepository>()),
  );
  getIt.registerLazySingleton<GetOrdersUseCase>(
    () => GetOrdersUseCase(getIt<OrderRepository>()),
  );
  getIt.registerLazySingleton<GetOrderDetailsUseCase>(
    () => GetOrderDetailsUseCase(getIt<OrderRepository>()),
  );
  getIt.registerLazySingleton<CancelOrderUseCase>(
    () => CancelOrderUseCase(getIt<OrderRepository>()),
  );

  // ── Features: Orders Presentation (BLoCs) ────────────────────────────────
  getIt.registerFactory<OrderBloc>(
    () => OrderBloc(
      checkoutUseCase: getIt<CheckoutUseCase>(),
      getOrdersUseCase: getIt<GetOrdersUseCase>(),
      getOrderDetailsUseCase: getIt<GetOrderDetailsUseCase>(),
      cancelOrderUseCase: getIt<CancelOrderUseCase>(),
    ),
  );

  // ── Features: Seller Data Layer ───────────────────────────────────────────
  getIt.registerLazySingleton<SellerRemoteDataSource>(
    () => SellerRemoteDataSourceImpl(dioClient: getIt<DioClient>()),
  );

  getIt.registerLazySingleton<SellerRepository>(
    () =>
        SellerRepositoryImpl(remoteDataSource: getIt<SellerRemoteDataSource>()),
  );

  // ── Features: Seller Domain Layer (Use Cases) ─────────────────────────────
  getIt.registerLazySingleton<GetSellerDashboardUseCase>(
    () => GetSellerDashboardUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<GetSellerProductsUseCase>(
    () => GetSellerProductsUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<GetSellerProductUseCase>(
    () => GetSellerProductUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<CreateSellerProductUseCase>(
    () => CreateSellerProductUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<UpdateSellerProductUseCase>(
    () => UpdateSellerProductUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<DeactivateSellerProductUseCase>(
    () => DeactivateSellerProductUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<GetSellerOrdersUseCase>(
    () => GetSellerOrdersUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<GetSellerOrderDetailsUseCase>(
    () => GetSellerOrderDetailsUseCase(getIt<SellerRepository>()),
  );
  getIt.registerLazySingleton<UpdateSellerOrderStatusUseCase>(
    () => UpdateSellerOrderStatusUseCase(getIt<SellerRepository>()),
  );

  // ── Features: Seller Presentation Layer (BLoCs) ───────────────────────────
  getIt.registerFactory<SellerDashboardBloc>(
    () => SellerDashboardBloc(
      getDashboardUseCase: getIt<GetSellerDashboardUseCase>(),
    ),
  );
  getIt.registerFactory<SellerProductsBloc>(
    () => SellerProductsBloc(
      getProductsUseCase: getIt<GetSellerProductsUseCase>(),
      getProductUseCase: getIt<GetSellerProductUseCase>(),
      createProductUseCase: getIt<CreateSellerProductUseCase>(),
      updateProductUseCase: getIt<UpdateSellerProductUseCase>(),
      deactivateProductUseCase: getIt<DeactivateSellerProductUseCase>(),
    ),
  );
  getIt.registerFactory<SellerOrdersBloc>(
    () => SellerOrdersBloc(
      getOrdersUseCase: getIt<GetSellerOrdersUseCase>(),
      getOrderDetailsUseCase: getIt<GetSellerOrderDetailsUseCase>(),
      updateOrderStatusUseCase: getIt<UpdateSellerOrderStatusUseCase>(),
    ),
  );
}
