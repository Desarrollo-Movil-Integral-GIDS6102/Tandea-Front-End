import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<AdminMetricasEntity>> obtenerMetricas() => _ejecutar(
        () async => (await remoteDataSource.obtenerMetricas()).toEntity(),
        'Error al cargar las métricas del panel global',
      );

  Future<Result<T>> _ejecutar<T>(
    Future<T> Function() accion,
    String fallback,
  ) async {
    try {
      return Success(await accion());
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(
        ServerFailure(
          e.message,
          statusCode: e.statusCode,
          fieldErrors: e.fieldErrors,
        ),
      );
    } catch (e) {
      return Error(ServerFailure('$fallback: $e'));
    }
  }
}
