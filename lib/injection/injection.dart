import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/dio_client.dart';
import 'package:tandea/core/network/server_health_service.dart';
import 'package:tandea/core/services/share_service.dart';
import 'package:tandea/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tandea/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/pagos/data/datasources/pago_remote_data_source.dart';
import 'package:tandea/features/pagos/data/repositories/pago_repository_impl.dart';
import 'package:tandea/features/pagos/data/services/comprobante_service_impl.dart';
import 'package:tandea/features/pagos/data/services/image_compressor_service.dart';
import 'package:tandea/features/pagos/data/services/permission_service.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';
import 'package:tandea/features/pagos/domain/services/comprobante_service.dart';
import 'package:tandea/features/pagos/domain/usecases/seleccionar_comprobante_usecase.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/tandas/data/datasources/tandas_remote_data_source.dart';
import 'package:tandea/features/tandas/data/repositories/tandas_repository_impl.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/crear_tanda_usecase.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_seguimiento_tanda_usecase.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_tanda_por_codigo_usecase.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';
import 'package:tandea/features/tandas/presentation/providers/crear_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/seguimiento_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/unirse_tanda_provider.dart';

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

  // Servicio de Health Check del servidor
  sl.registerLazySingleton<ServerHealthService>(
    () => ServerHealthService(dio: sl<Dio>()),
  );

  // Servicio para compartir con share_plus
  sl.registerLazySingleton<ShareService>(
    () => ShareServiceImpl(),
  );

  // Servicios de captura, permisos y compresión de comprobantes (AP-04)
  sl.registerLazySingleton<ImagePicker>(
    () => ImagePicker(),
  );

  sl.registerLazySingleton<ImageCompressorService>(
    () => FlutterImageCompressorServiceImpl(),
  );

  sl.registerLazySingleton<PermissionService>(
    () => PermissionServiceImpl(),
  );

  sl.registerLazySingleton<ComprobanteService>(
    () => ComprobanteServiceImpl(
      imagePicker: sl<ImagePicker>(),
      compressorService: sl<ImageCompressorService>(),
      permissionService: sl<PermissionService>(),
    ),
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
  // 5. Casos de Uso (Domain UseCases)
  // ----------------------------------------------------
  sl.registerLazySingleton<CrearTandaUseCase>(
    () => CrearTandaUseCase(repository: sl<TandasRepository>()),
  );

  sl.registerLazySingleton<ObtenerTandaPorCodigoUseCase>(
    () => ObtenerTandaPorCodigoUseCase(repository: sl<TandasRepository>()),
  );

  sl.registerLazySingleton<UnirseTandaUseCase>(
    () => UnirseTandaUseCase(repository: sl<TandasRepository>()),
  );

  sl.registerLazySingleton<ObtenerSeguimientoTandaUseCase>(
    () => ObtenerSeguimientoTandaUseCase(repository: sl<TandasRepository>()),
  );

  sl.registerLazySingleton<SeleccionarComprobanteUseCase>(
    () => SeleccionarComprobanteUseCase(comprobanteService: sl<ComprobanteService>()),
  );

  // ----------------------------------------------------
  // 6. Providers / State Management
  // ----------------------------------------------------
  // AuthSessionProvider para gestión de sesión y roles en GoRouter
  sl.registerLazySingleton<AuthSessionProvider>(
    () => AuthSessionProvider(),
  );

  sl.registerFactory<AuthProvider>(
    () => AuthProvider(
      authRepository: sl<AuthRepository>(),
      sessionProvider: sl<AuthSessionProvider>(),
    ),
  );

  sl.registerFactory<TandasProvider>(
    () => TandasProvider(tandasRepository: sl<TandasRepository>()),
  );

  sl.registerFactory<CrearTandaProvider>(
    () => CrearTandaProvider(crearTandaUseCase: sl<CrearTandaUseCase>()),
  );

  sl.registerFactory<UnirseTandaProvider>(
    () => UnirseTandaProvider(
      obtenerTandaPorCodigoUseCase: sl<ObtenerTandaPorCodigoUseCase>(),
      unirseTandaUseCase: sl<UnirseTandaUseCase>(),
    ),
  );

  sl.registerFactory<SeguimientoTandaProvider>(
    () => SeguimientoTandaProvider(
      obtenerSeguimientoUseCase: sl<ObtenerSeguimientoTandaUseCase>(),
    ),
  );

  sl.registerFactory<PagoProvider>(
    () => PagoProvider(
      pagoRepository: sl<PagoRepository>(),
      seleccionarComprobanteUseCase: sl<SeleccionarComprobanteUseCase>(),
    ),
  );
}

/// Alias para conveniencia
Future<void> init() => initDependencies();
