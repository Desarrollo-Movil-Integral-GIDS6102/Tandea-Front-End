import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/data/datasources/tandas_remote_data_source.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Implementación del repositorio de tandas en la capa de datos.
class TandasRepositoryImpl implements TandasRepository {
  final TandasRemoteDataSource remoteDataSource;

  TandasRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<TandaEntity>>> getTandas() async {
    try {
      final list = await remoteDataSource.getTandas();
      return Success(list);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al obtener tandas: $e'));
    }
  }

  @override
  Future<Result<TandaEntity>> getTandaById(String id) async {
    try {
      final tanda = await remoteDataSource.getTandaById(id);
      return Success(tanda);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al obtener la tanda: $e'));
    }
  }

  @override
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> tandaData) async {
    try {
      final created = await remoteDataSource.createTanda(tandaData);
      return Success(created);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al crear la tanda: $e'));
    }
  }
}
