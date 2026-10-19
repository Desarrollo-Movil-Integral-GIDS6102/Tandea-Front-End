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
  Future<Result<PagoEntity>> registrarPago({
    required String tandaId,
    required double monto,
    String? comprobanteUrl,
  }) async {
    try {
      final pago = await remoteDataSource.registrarPago(
        tandaId: tandaId,
        monto: monto,
        comprobanteUrl: comprobanteUrl,
      );
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
}
