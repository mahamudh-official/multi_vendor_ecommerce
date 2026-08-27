import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

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
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Register all application dependencies.
/// Call this once from [main] before [runApp].
Future<void> configureDependencies() async {
  // ── Core: Secure Storage ─────────────────────────────────────────────────
  const flutterSecureStorage = FlutterSecureStorage();
  final secureStorageService = const SecureStorageService(flutterSecureStorage);
  getIt.registerLazySingleton<SecureStorageService>(() => secureStorageService);

  // ── Core: Network ────────────────────────────────────────────────────────
  final dioClient = DioClient();
  // Attach AuthInterceptor for transparent Bearer token injection and 401 refresh
  dioClient.addInterceptor(
    AuthInterceptor(
      secureStorage: secureStorageService,
      dio: dioClient.client,
    ),
  );
  getIt.registerLazySingleton<DioClient>(() => dioClient);

  // ── Features: Auth Data Layer ────────────────────────────────────────────
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

  // ── Features: Auth Domain Layer (Use Cases) ──────────────────────────────
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

  // ── Features: Auth Presentation (BLoC) ───────────────────────────────────
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      checkAuthStatusUseCase: getIt<CheckAuthStatusUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      refreshTokenUseCase: getIt<RefreshTokenUseCase>(),
    ),
  );
}
