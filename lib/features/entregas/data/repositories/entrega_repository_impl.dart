import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/entregas/domain/entities/entrega_entity.dart';
import 'package:tandea/features/entregas/domain/repositories/entrega_repository.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';

class EntregaRepositoryImpl implements EntregaRepository {
  final ApiClient apiClient;

  EntregaRepositoryImpl({required this.apiClient});

  static const _base = ApiConstants.entregasEndpoint;

  @override
  Future<Result<EntregaEntity>> registrar({
    required int idNumber,
    required double transferencia,
    required double efectivo,
    required ComprobanteArchivo evidencia,
  }) =>
      _ejecutar(
        () async => _entrega(
          (await apiClient.post<dynamic>(
            _base,
            data: FormData.fromMap(<String, dynamic>{
              'idNumber': idNumber.toString(),
              'transferAmount': formatearMontoApi(transferencia),
              'cashAmount': formatearMontoApi(efectivo),
              'file': MultipartFile.fromBytes(
                evidencia.bytes,
                filename: evidencia.nombre,
                contentType: DioMediaType.parse(evidencia.mimeType),
              ),
            }),
          ))
              .data,
        ),
        'Error al registrar la entrega',
      );

  @override
  Future<Result<EntregaEntity>> obtener(int idPayout) => _ejecutar(
        () async => _entrega((await apiClient.get<dynamic>('$_base/$idPayout')).data),
        'Error al consultar la entrega',
      );

  @override
  Future<Result<EntregaEntity>> confirmar(int idPayout) => _ejecutar(
        () async => _entrega((await apiClient.patch<dynamic>('$_base/$idPayout/confirmar')).data),
        'Error al confirmar la entrega',
      );

  @override
  Future<Result<void>> reportarProblema(int idPayout, String motivo) => _ejecutar(
        () async {
          await apiClient.post<dynamic>('$_base/$idPayout/problema', data: {'motivo': motivo.trim()});
        },
        'Error al reportar el problema',
      );

  static EntregaEntity _entrega(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return EntregaEntity.fromJson(raw['data'] as Map<String, dynamic>);
    }
    throw const ServerException(message: 'Formato de respuesta inválido');
  }

  Future<Result<T>> _ejecutar<T>(Future<T> Function() accion, String fallback) async {
    try {
      try {
        return Success(await accion());
      } on DioException catch (e) {
        NetworkErrorHandler.handleDioException(e, fallbackMessage: fallback);
      }
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('$fallback: $e'));
    }
  }
}
