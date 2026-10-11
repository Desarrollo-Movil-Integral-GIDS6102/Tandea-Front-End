import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/network_error_handler.dart';

void main() {
  group('NetworkErrorHandler Tests', () {
    test('connectionError lanza NetworkException con mensaje de sin conexión', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      expect(
        () => NetworkErrorHandler.handleDioException(dioException),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('Sin conexión a internet'),
          ),
        ),
      );
    });

    test('connectionTimeout lanza NetworkException con mensaje de servidor no respondió a tiempo', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        () => NetworkErrorHandler.handleDioException(dioException),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('no respondió a tiempo'),
          ),
        ),
      );
    });

    test('receiveTimeout lanza NetworkException con mensaje de timeout de respuesta', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );

      expect(
        () => NetworkErrorHandler.handleDioException(dioException),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('tardó demasiado en responder'),
          ),
        ),
      );
    });

    test('401 lanza UnauthorizedException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: <String, dynamic>{'message': 'No autorizado'},
        ),
      );

      expect(
        () => NetworkErrorHandler.handleDioException(dioException),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            contains('No autorizado'),
          ),
        ),
      );
    });

    test('404 lanza ServerException con statusCode 404', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
          data: <String, dynamic>{'message': 'Ruta no encontrada'},
        ),
      );

      expect(
        () => NetworkErrorHandler.handleDioException(dioException),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('Ruta no encontrada')),
        ),
      );
    });

    test('500 lanza ServerException con statusCode 500', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Internal Server Error'},
        ),
      );

      expect(
        () => NetworkErrorHandler.handleDioException(dioException),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Internal Server Error')),
        ),
      );
    });
  });
}
