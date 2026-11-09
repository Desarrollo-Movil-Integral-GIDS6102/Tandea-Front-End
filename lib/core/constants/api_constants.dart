import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String _urlRailway = 'https://tandea-back-end-production-8546.up.railway.app/api/v1';

  /// URL base de la API REST (versión 1).
  ///
  /// Toma `API_BASE_URL` del archivo `.env`. Un `--dart-define=API_BASE_URL=...` tiene
  /// prioridad, y si no hay ninguno de los dos se usa Railway.
  static String get apiBaseUrl {
    const definida = String.fromEnvironment('API_BASE_URL');
    if (definida.isNotEmpty) return definida;

    final delEnv = dotenv.isInitialized ? dotenv.maybeGet('API_BASE_URL') : null;
    return delEnv == null || delEnv.isEmpty ? _urlRailway : delEnv;
  }

  /// Alias de compatibilidad hacia [apiBaseUrl].
  static String get baseUrl => apiBaseUrl;

  /// URL de comprobación de salud del backend (Health Check).
  ///
  /// Se ubica en la raíz del host (`/health`), fuera del prefijo `/api/v1`.
  static String get healthUrl {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final portSuffix = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$portSuffix/health';
    }
    return 'https://tandea-back-end-production-8546.up.railway.app/health';
  }

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String meEndpoint = '/auth/profile';
  static const String perfilEndpoint = '/auth/perfil';
  static const String perfilCodigoPasswordEndpoint = '/auth/perfil/password/codigo';
  static const String perfilPasswordEndpoint = '/auth/perfil/password';
  static const String recuperarPasswordEndpoint = '/auth/password/recuperar';
  static const String restablecerPasswordEndpoint = '/auth/password/restablecer';

  // Tandas endpoints
  static const String tandasEndpoint = '/tandas';
  static const String misTandasEndpoint = '/tandas/mias';


  // Pagos endpoints
  static const String pagosEndpoint = '/pagos';

  // Entregas endpoints
  static const String entregasEndpoint = '/entregas';

  // Notificaciones endpoints
  static const String notificacionesEndpoint = '/notificaciones';
  static const String fcmTokenEndpoint = '/users/me/fcm-token';

  // Admin endpoints
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminTandasEndpoint = '/admin/tandas';
}
