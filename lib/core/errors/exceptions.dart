class ServerException implements Exception {
  final String message;
  final int? statusCode;

  /// Errores de validación por campo (`details` del 422 del backend): campo → mensaje.
  final Map<String, String> fieldErrors;

  const ServerException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'No se pudo conectar al servidor. Revisa tu conexión a internet.',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({
    this.message = 'Error al acceder a los datos locales.',
  });

  @override
  String toString() => 'CacheException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({
    this.message = 'Sesión expirada o no autorizada.',
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}
