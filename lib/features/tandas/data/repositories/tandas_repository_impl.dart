import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/data/datasources/tandas_remote_data_source.dart';
import 'package:tandea/features/tandas/data/models/tanda_model.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';

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
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol}) async {
    try {
      final list = await remoteDataSource.getMisTandas(rol: rol);
      return Success(list);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error inesperado al consultar mis tandas: $e'));
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

  @override
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode) async {
    try {
      final tanda = await remoteDataSource.getTandaByInviteCode(inviteCode);
      return Success(tanda);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error inesperado al consultar código: $e'));
    }
  }

  @override
  Future<Result<TandaEntity>> iniciarTanda(String id) async {
    try {
      return Success(await remoteDataSource.updateStatus(id, 'ACTIVA'));
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al iniciar la tanda: $e'));
    }
  }

  @override
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params) async {
    try {
      final rawData = await remoteDataSource.joinTanda(params.toJson());
      final data = rawData['data'] is Map<String, dynamic>
          ? rawData['data'] as Map<String, dynamic>
          : rawData;
      final tandaJson = data['tanda'] is Map<String, dynamic>
          ? data['tanda'] as Map<String, dynamic>
          : data;
      final tanda = TandaModel.fromJson(tandaJson);
      final numeroAsignado =
          (data['numeroAsignado'] as num?)?.toInt() ??
              (params.selectedNumbers.isNotEmpty ? params.selectedNumbers.first : 1);
      final numerosAsignados = (data['numerosAsignados'] as List?)
              ?.map((n) => (n as num).toInt())
              .toList() ??
          [numeroAsignado];
      final isDeadNumber = (data['isDeadNumber'] as bool?) ?? false;
      final mensaje = (rawData['mensaje'] ?? 'Te has unido exitosamente a la tanda').toString();

      return Success(
        UnirseTandaResult(
          tanda: tanda,
          numeroAsignado: numeroAsignado,
          numerosAsignados: numerosAsignados,
          isDeadNumber: isDeadNumber,
          mensaje: mensaje,
        ),
      );
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error inesperado al unirse a la tanda: $e'));
    }
  }
}
