import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/network/server_health_service.dart';

void main() {
  group('ServerHealthService Tests', () {
    test('retorna Success(true) cuando el servidor responde status 200 con status ok', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'status': 'ok',
                  'timestamp': '2026-10-11T00:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final service = ServerHealthService(dio: dio);
      final result = await service.checkHealth();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isTrue);
    });

    test('retorna Error cuando el servidor responde con status 500', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 500,
                  data: <String, dynamic>{'message': 'Error en base de datos'},
                ),
              ),
            );
          },
        ),
      );

      final service = ServerHealthService(dio: dio);
      final result = await service.checkHealth();

      expect(result.isFailure, isTrue);
    });

    test('retorna Error cuando hay connectionError', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      final service = ServerHealthService(dio: dio);
      final result = await service.checkHealth();

      expect(result.isFailure, isTrue);
    });

    test('retorna Success(true) cuando el primer endpoint da 404 pero el fallback responde 200', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/api/v1/health')) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{'status': 'ok'},
                ),
              );
            } else {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 404,
                    data: <String, dynamic>{'message': 'Cannot GET /health'},
                  ),
                ),
              );
            }
          },
        ),
      );

      final service = ServerHealthService(dio: dio);
      final result = await service.checkHealth();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isTrue);
    });
  });
}
