import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_detalle_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_usuario_entity.dart';
import 'package:tandea/features/admin/domain/repositories/admin_repository.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<AdminMetricasEntity>> obtenerMetricas() => _ejecutar(
        () async => (await remoteDataSource.obtenerMetricas()).toEntity(),
        'Error al cargar las métricas del panel global',
      );

  @override
  Future<Result<List<AdminUsuarioEntity>>> buscarUsuarios({
    String? q,
    bool? active,
  }) =>
      _ejecutar(
        () async {
          final modelos = await remoteDataSource.buscarUsuarios(
            q: q,
            active: active,
          );
          return modelos.map((m) => m.toEntity()).toList();
        },
        'Error al buscar usuarios',
      );

  @override
  Future<Result<AdminUsuarioEntity>> suspenderUsuario(
    int idUser, {
    String? motivo,
  }) =>
      _ejecutar(
        () async => (await remoteDataSource.suspenderUsuario(
          idUser,
          motivo: motivo,
        ))
            .toEntity(),
        'Error al suspender al usuario',
      );

  @override
  Future<Result<List<TandaEntity>>> listarTandasAdmin({
    String? search,
    String? status,
  }) =>
      _ejecutar(
        () async {
          final modelos = await remoteDataSource.listarTandasAdmin(
            search: search,
            status: status,
          );
          return modelos.map((m) => m.toEntity()).toList();
        },
        'Error al listar las tandas de la plataforma',
      );

  @override
  Future<Result<List<AdminDisputaEntity>>> listarDisputas({
    String? status,
    int? idTanda,
  }) =>
      _ejecutar(
        () async {
          final modelos = await remoteDataSource.listarDisputas(
            status: status,
            idTanda: idTanda,
          );
          return modelos.map((m) => m.toEntity()).toList();
        },
        'Error al listar las disputas reportadas',
      );

  @override
  Future<Result<AdminDisputaDetalleEntity>> obtenerDetalleDisputa(
    int idDispute,
  ) =>
      _ejecutar(
        () async =>
            (await remoteDataSource.obtenerDetalleDisputa(idDispute)).toEntity(),
        'Error al consultar el detalle de la disputa',
      );

  @override
  Future<Result<AdminDisputaEntity>> resolverDisputa({
    required int idDispute,
    required String accion,
    required String notas,
  }) =>
      _ejecutar(
        () async => (await remoteDataSource.resolverDisputa(
          idDispute: idDispute,
          accion: accion,
          notas: notas,
        ))
            .toEntity(),
        'Error al resolver la disputa',
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
