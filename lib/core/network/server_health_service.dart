import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/core/utils/result.dart';

/// Servicio para comprobar la conectividad y disponibilidad del backend desplegado.
class ServerHealthService {
  final Dio _dio;

  ServerHealthService({Dio? dio}) : _dio = dio ?? Dio();

  /// Realiza una petición GET a [ApiConstants.healthUrl] para verificar que el servidor esté activo.
  ///
  /// Retorna [Success(true)] si el backend responde satisfactoriamente (status 200 y status "ok").
  /// Retorna [Error(Failure)] con el detalle descriptivo del fallo si la conexión no fue exitosa.
  Future<Result<bool>> checkHealth() async {
    final urlsToTry = <String>[
      ApiConstants.healthUrl,
      '${ApiConstants.apiBaseUrl}/health',
    ];

    DioException? lastDioException;
    for (final url in urlsToTry) {
      try {
        final response = await _dio.get<dynamic>(
          url,
          options: Options(
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

        final statusCode = response.statusCode;
        if (statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['status'] == 'ok') {
            return const Success(true);
          }
          return const Success(true);
        }
        return Error(
          ServerFailure(
            'El health check respondió con código $statusCode',
            statusCode: statusCode,
          ),
        );
      } on DioException catch (e) {
        lastDioException = e;
        // Si el endpoint no existe en esta ruta (404), intentamos la ruta alternativa
        if (e.response?.statusCode == 404) {
          continue;
        }
        return _mapDioException(e);
      } catch (e) {
        return Error(ServerFailure('Error inesperado al conectar al servidor: $e'));
      }
    }

    if (lastDioException != null) {
      return _mapDioException(lastDioException);
    }
    return const Error(ServerFailure('No se pudo verificar el estado del servidor'));
  }

  Result<bool> _mapDioException(DioException e) {
    try {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'No se pudo conectar al endpoint de salud',
      );
    } on NetworkException catch (ne) {
      return Error(NetworkFailure(ne.message));
    } on ServerException catch (se) {
      return Error(ServerFailure(se.message, statusCode: se.statusCode));
    } on UnauthorizedException catch (ue) {
      return Error(UnauthorizedFailure(ue.message));
    } catch (ex) {
      return Error(ServerFailure('Error al verificar servidor: $ex'));
    }
  }
}
