class AppConstants {
  static const String appName = 'Tandea';
  static const String appTagline = 'Gestión de ahorro rotativo (tandas)';

  // Almacenamiento seguro
  static const String tokenKey = 'auth_token';

  // Timeouts aumentados a 30 segundos por posibles cold starts en Railway
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
