import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/data/datasources/tandas_remote_data_source.dart';
import 'package:tandea/features/tandas/domain/entities/movimiento_historial.dart';
import 'package:tandea/features/tandas/domain/repositories/historial_tanda_repository.dart';

class HistorialTandaRepositoryImpl implements HistorialTandaRepository {
  final TandasRemoteDataSource remoteDataSource;

  HistorialTandaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<PaginaHistorial>> getHistorial(String idTanda, {String? cursor, int limit = 20}) async {
    try {
      return Success(await remoteDataSource.getHistorial(idTanda, cursor: cursor, limit: limit));
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al obtener el historial: $e'));
    }
  }
}
