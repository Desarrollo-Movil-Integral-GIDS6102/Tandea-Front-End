import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/constants/app_constants.dart';
import 'package:tandea/core/network/api_client.dart';

/// Cliente Dio configurado para la comunicación con la API REST.
class DioClient {
  final Dio _dio;

  DioClient({Dio? dio, ApiClient? apiClient})
      : _dio = dio ??
            (apiClient?.dio ??
                Dio(
                  BaseOptions(
                    baseUrl: ApiConstants.apiBaseUrl,
                    connectTimeout: AppConstants.connectionTimeout,
                    receiveTimeout: AppConstants.receiveTimeout,
                    headers: const <String, dynamic>{
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                    },
                  ),
                ));

  Dio get dio => _dio;
}
