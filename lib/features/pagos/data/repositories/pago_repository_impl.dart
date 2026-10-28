import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/data/datasources/pago_remote_data_source.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';

/// Implementación del repositorio de pagos en la capa de datos.
class PagoRepositoryImpl implements PagoRepository {
  final PagoRemoteDataSource remoteDataSource;

  PagoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<PagoEntity>>> getPagosByTanda(String tandaId) async {
    try {
      final list = await remoteDataSource.getPagosByTanda(tandaId);
      return Success(list);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al consultar pagos: $e'));
    }
  }

  @override
  Future<Result<PagoEntity>> registrarPago(RegistrarPagoParams params) async {
    try {
      final pago = await remoteDataSource.registrarPago(params);
      return Success(pago);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error al registrar pago: $e'));
    }
  }

  @override
  Future<Result<PagoEntity>> obtenerPago(int idPayment) =>
      _ejecutar(() => remoteDataSource.obtenerPago(idPayment), 'Error al consultar el pago');

  @override
  Future<Result<PagoEntity>> confirmarPago(int idPayment) =>
      _ejecutar(() => remoteDataSource.confirmarPago(idPayment), 'Error al confirmar el pago');

  @override
  Future<Result<PagoEntity>> rechazarPago(int idPayment, String motivo) =>
      _ejecutar(() => remoteDataSource.rechazarPago(idPayment, motivo), 'Error al rechazar el pago');

  Future<Result<PagoEntity>> _ejecutar(Future<PagoEntity> Function() accion, String mensaje) async {
    try {
      return Success(await accion());
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('$mensaje: $e'));
    }
  }
}
