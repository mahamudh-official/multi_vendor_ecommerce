import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Register all application dependencies.
///
/// Call this once from [main] before [runApp].
///
/// Dependency graph (Step 1 — foundation only):
///   FlutterSecureStorage → SecureStorageService
///   DioClient (standalone)
///
/// Step 2 will add:
///   DioClient + SecureStorageService → AuthRemoteDataSource
///   AuthRemoteDataSource → AuthRepository
///   AuthRepository → LoginUseCase, RegisterUseCase
///   UseCases → AuthCubit
Future<void> configureDependencies() async {
  // ── Core: Secure Storage ─────────────────────────────────────────────────
  const flutterSecureStorage = FlutterSecureStorage();
  getIt.registerLazySingleton<SecureStorageService>(
    () => const SecureStorageService(flutterSecureStorage),
  );

  // ── Core: Network ────────────────────────────────────────────────────────
  getIt.registerLazySingleton<DioClient>(() => DioClient());

  // Future registrations will follow the pattern:
  // getIt.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(getIt<DioClient>()),
  // );
}
