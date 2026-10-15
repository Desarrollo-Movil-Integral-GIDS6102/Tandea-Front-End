class ApiConstants {
  /// URL base de la API REST (versión 1).
  ///
  /// Por defecto apunta al entorno de producción en Railway, y puede sobreescribirse
  /// en tiempo de compilación o ejecución mediante `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tandea-back-end-production.up.railway.app/api/v1',
  );

  /// Alias de compatibilidad hacia [apiBaseUrl].
  static const String baseUrl = apiBaseUrl;

  /// URL de comprobación de salud del backend (Health Check).
  ///
  /// Se ubica en la raíz del host (`/health`), fuera del prefijo `/api/v1`.
  static String get healthUrl {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final portSuffix = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$portSuffix/health';
    }
    return 'https://tandea-back-end-production.up.railway.app/health';
  }

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String meEndpoint = '/auth/profile';

  // Tandas endpoints
  static const String tandasEndpoint = '/tandas';

  // Pagos endpoints
  static const String pagosEndpoint = '/pagos';

  // Entregas endpoints
  static const String entregasEndpoint = '/entregas';

  // Notificaciones endpoints
  static const String notificacionesEndpoint = '/notificaciones';

  // Admin endpoints
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminTandasEndpoint = '/admin/tandas';
}
