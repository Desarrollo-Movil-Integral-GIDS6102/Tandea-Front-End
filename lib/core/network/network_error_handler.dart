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

      if (statusCode == 409) {
        throw ServerException(
          message: extractErrorMessage(e) ?? 'El correo electrónico ya se encuentra registrado. Intenta iniciar sesión con tu cuenta.',
          statusCode: 409,
        );
      }

      if (statusCode == 422) {
        throw ServerException(
          message: extractErrorMessage(e) ?? 'Uno o más datos ingresados son inválidos. Revisa el formulario.',
          statusCode: 422,
        );
      }

      if (statusCode >= 500 && statusCode <= 599) {
        throw ServerException(
          message: extractErrorMessage(e) ?? 'Error interno del servidor ($statusCode). Intenta nuevamente más tarde.',
          statusCode: statusCode,
        );
      }
    }

    // 3. Fallback genérico para otros errores HTTP (400, etc.)
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
      // 1. Si el backend incluye detalles específicos por campo (Zod / DTOs),
      // extraer los mensajes específicos de cada campo en lugar del mensaje genérico.
      if (data['details'] is List) {
        final details = data['details'] as List<dynamic>;
        final detailMessages = details
            .map((dynamic item) {
              if (item is Map<String, dynamic> && item['message'] != null) {
                return item['message'].toString().trim();
              }
              return null;
            })
            .whereType<String>()
            .where((String msg) => msg.isNotEmpty)
            .toSet()
            .toList();

        if (detailMessages.isNotEmpty) {
          return detailMessages.join('\n');
        }
      }

      // 2. Si viene lista de mensajes en 'message'
      final rawMessage = data['message'] ?? data['error'];
      if (rawMessage is List<dynamic>) {
        return rawMessage.map((dynamic item) => item.toString()).join('\n');
      }

      if (rawMessage != null && rawMessage.toString().trim().isNotEmpty) {
        final msgStr = rawMessage.toString().trim();
        if (msgStr.contains('uno o más campos son inválidos o faltan en la petición')) {
          return 'Verifica los campos del formulario. Hay datos incompletos o con formato inválido.';
        }
        return msgStr;
      }
    }
    return null;
  }
}
