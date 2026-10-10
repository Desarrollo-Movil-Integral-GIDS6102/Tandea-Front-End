import 'package:dio/dio.dart';
import 'package:tandea/core/network/api_client.dart';

/// Cliente Dio mantenido por compatibilidad que expone la instancia de red.
class DioClient {
  final Dio _dio;

  DioClient({Dio? dio, ApiClient? apiClient})
      : _dio = dio ?? (apiClient?.dio ?? Dio());

  Dio get dio => _dio;
}
