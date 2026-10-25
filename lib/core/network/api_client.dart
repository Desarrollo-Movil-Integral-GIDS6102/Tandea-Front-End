import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/constants/app_constants.dart';

/// Interceptor que inyecta automáticamente el token JWT en el encabezado
/// `Authorization: Bearer <token>` y gestiona las respuestas de error `401 Unauthorized`.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final String tokenKey;
  final void Function()? onUnauthorized;

  AuthInterceptor({
    required this.storage,
    this.tokenKey = AppConstants.tokenKey,
    this.onUnauthorized,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Si la petición no cuenta con cabecera Authorization previa, obtener token seguro
    if (!options.headers.containsKey('Authorization')) {
      final token = await storage.read(key: tokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Manejo de error 401 (Sesión expirada o token no autorizado)
    if (err.response?.statusCode == 401) {
      // 1. Limpiar token de sesión en almacenamiento seguro
      await storage.delete(key: tokenKey);

      // 2. Notificar callback de sesión expirada si fue configurado
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}

/// Cliente HTTP centralizado basado en Dio para la comunicación con la API REST.
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage storage;
  final String tokenKey;
  final void Function()? onUnauthorized;

  ApiClient({
    required this.storage,
    Dio? dio,
    this.tokenKey = AppConstants.tokenKey,
    this.onUnauthorized,
    String? baseUrl,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConstants.apiBaseUrl,
                connectTimeout: AppConstants.connectionTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                headers: const <String, dynamic>{
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.addAll([
      AuthInterceptor(
        storage: storage,
        tokenKey: tokenKey,
        onUnauthorized: onUnauthorized,
      ),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  /// Instancia de Dio subyacente
  Dio get dio => _dio;

  // ===================== GESTIÓN DE TOKEN =====================

  /// Guarda el token JWT en el almacenamiento seguro
  Future<void> saveToken(String token) async {
    await storage.write(key: tokenKey, value: token);
  }

  /// Obtiene el token JWT del almacenamiento seguro
  Future<String?> getToken() async {
    return storage.read(key: tokenKey);
  }

  /// Elimina el token JWT del almacenamiento seguro
  Future<void> deleteToken() async {
    await storage.delete(key: tokenKey);
  }

  /// Verifica si existe un token almacenado
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ===================== MÉTODOS HTTP =====================

  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
