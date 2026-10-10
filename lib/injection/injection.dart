import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/dio_client.dart';
import 'package:tandea/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tandea/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/pagos/data/datasources/pago_remote_data_source.dart';
import 'package:tandea/features/pagos/data/repositories/pago_repository_impl.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/tandas/data/datasources/tandas_remote_data_source.dart';
import 'package:tandea/features/tandas/data/repositories/tandas_repository_impl.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';

final sl = GetIt.instance;

/// Inicializa el contenedor de inyección de dependencias (Service Locator).
Future<void> initDependencies() async {
  // ----------------------------------------------------
  // 1. Almacenamiento seguro
  // ----------------------------------------------------
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ----------------------------------------------------
  // 2. Red y Cliente HTTP
  // ----------------------------------------------------
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(storage: sl<FlutterSecureStorage>()),
  );

  // Instancia de Dio subyacente de ApiClient
  sl.registerLazySingleton<Dio>(
    () => sl<ApiClient>().dio,
  );

  // Compatibilidad con DioClient
  sl.registerLazySingleton<DioClient>(
    () => DioClient(apiClient: sl<ApiClient>()),
  );

  // ----------------------------------------------------
  // 3. DataSources
  // ----------------------------------------------------
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<TandasRemoteDataSource>(
    () => TandasRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<PagoRemoteDataSource>(
    () => PagoRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // ----------------------------------------------------
  // 4. Repositorios (Domain contracts -> Data implementations)
  // ----------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      storage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerLazySingleton<TandasRepository>(
    () => TandasRepositoryImpl(
      remoteDataSource: sl<TandasRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<PagoRepository>(
    () => PagoRepositoryImpl(
      remoteDataSource: sl<PagoRemoteDataSource>(),
    ),
  );

  // ----------------------------------------------------
  // 5. Providers / State Management
  // ----------------------------------------------------
  // AuthSessionProvider para gestión de sesión y roles en GoRouter
  sl.registerLazySingleton<AuthSessionProvider>(
    () => AuthSessionProvider(),
  );

  sl.registerFactory<AuthProvider>(
    () => AuthProvider(authRepository: sl<AuthRepository>()),
  );

  sl.registerFactory<TandasProvider>(
    () => TandasProvider(tandasRepository: sl<TandasRepository>()),
  );

  sl.registerFactory<PagoProvider>(
    () => PagoProvider(pagoRepository: sl<PagoRepository>()),
  );
}

/// Alias para conveniencia
Future<void> init() => initDependencies();
