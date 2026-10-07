import 'package:get_it/get_it.dart';
import 'package:tandea/core/network/dio_client.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core: Red e infraestructura
  sl.registerLazySingleton<DioClient>(() => DioClient());

  // Features registration will be added here as features are implemented:
  // - DataSources
  // - Repositories
  // - UseCases
  // - Providers / Blocs
}
