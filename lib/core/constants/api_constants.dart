class ApiConstants {
  static const String baseUrl = 'https://api.tandea.app/api/v1';

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';

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
