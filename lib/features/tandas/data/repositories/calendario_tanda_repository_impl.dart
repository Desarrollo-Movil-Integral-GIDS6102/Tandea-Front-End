import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/data/datasources/tandas_remote_data_source.dart';
import 'package:tandea/features/tandas/domain/entities/calendario_tanda.dart';
import 'package:tandea/features/tandas/domain/repositories/calendario_tanda_repository.dart';

class CalendarioTandaRepositoryImpl implements CalendarioTandaRepository {
  final TandasRemoteDataSource remoteDataSource;

  CalendarioTandaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<CalendarioTanda>> getCalendario(String idTanda) async {
    try {
      return Success(await remoteDataSource.getCalendario(idTanda));
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al obtener el calendario: $e'));
    }
  }
}

