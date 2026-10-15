import 'package:dio/dio.dart';
import 'package:tandea/core/errors/exceptions.dart';

/// Helper centralizado para transformar excepciones de Dio en excepciones específicas
/// de la arquitectura de la aplicación (NetworkException, ServerException, UnauthorizedException).
class NetworkErrorHandler {
  /// Procesa una [DioException] y lanza la excepción de negocio correspondiente.
  static Never handleDioException(
    DioException e, {
    String fallbackMessage = 'Error en la petición de red',
  }) {
    // 1. Verificación de errores de conectividad y timeout
    switch (e.type) {
      case DioExceptionType.connectionError:
        throw const NetworkException(
          message: 'Sin conexión a internet. Revisa tu red móvil o Wi-Fi.',
        );
      case DioExceptionType.connectionTimeout:
        throw const NetworkException(
          message: 'El servidor no respondió a tiempo al conectar. Revisa tu conexión o intenta más tarde.',
        );
      case DioExceptionType.receiveTimeout:
        throw const NetworkException(
          message: 'El servidor tardó demasiado en responder. El servicio podría estar iniciando.',
        );
      case DioExceptionType.sendTimeout:
        throw const NetworkException(
          message: 'Tiempo de envío agotado. La petición no pudo completarse.',
        );
      default:
        break;
    }

    // 2. Errores HTTP con código de estado del servidor
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      if (statusCode == 401) {
        throw UnauthorizedException(
          message: extractErrorMessage(e) ?? 'Credenciales inválidas o sesión no autorizada.',
        );
      }

      if (statusCode == 404) {
        throw ServerException(
          message: extractErrorMessage(e) ?? 'Recurso no encontrado en el servidor (404).',
          statusCode: 404,
        );
      }

      if (statusCode >= 500 && statusCode <= 599) {
        throw ServerException(
          message: extractErrorMessage(e) ?? 'Error interno del servidor ($statusCode). Intenta nuevamente más tarde.',
          statusCode: statusCode,
        );
      }
    }

    // 3. Fallback genérico para otros errores HTTP (400, 409, 422, etc.)
    final message = extractErrorMessage(e) ?? e.message ?? fallbackMessage;
    throw ServerException(
      message: message,
      statusCode: statusCode,
    );
  }

  /// Extrae el mensaje de error estructurado retornado por el backend.
  static String? extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is List<dynamic>) {
        return message.map((dynamic item) => item.toString()).join('\n');
      }
      if (message != null) {
        return message.toString();
      }
    }
    return null;
  }
}
