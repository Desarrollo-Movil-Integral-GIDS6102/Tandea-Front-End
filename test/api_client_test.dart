import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/network/api_client.dart';

class _Storage extends Fake implements FlutterSecureStorage {
  int borrados = 0;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      'token';

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      borrados++;
}

class _Adapter implements HttpClientAdapter {
  final int status;
  RequestOptions? ultima;

  _Adapter({this.status = 200});

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async {
    ultima = options;
    return ResponseBody.fromString('{}', status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final storage = _Storage();

  ApiClient cliente(_Adapter adapter, {void Function()? onUnauthorized}) => ApiClient(
        storage: storage,
        onUnauthorized: onUnauthorized,
        dio: Dio(BaseOptions(
          baseUrl: 'http://api.test',
          headers: const {'Content-Type': 'application/json'},
        ))
          ..httpClientAdapter = adapter,
      );

  test('una petición sin cuerpo no declara JSON (Body cannot be empty)', () async {
    final adapter = _Adapter();

    await cliente(adapter).dio.post<dynamic>('/auth/perfil/password/codigo');

    expect(adapter.ultima!.contentType, isNull);
    expect(adapter.ultima!.headers['Authorization'], 'Bearer token');
  });

  test('una petición con cuerpo conserva application/json', () async {
    final adapter = _Adapter();

    await cliente(adapter).dio.post<dynamic>('/auth/login', data: {'a': 1});

    expect(adapter.ultima!.contentType, 'application/json');
  });

  test('un 401 con token cierra la sesión', () async {
    var cerrada = false;
    final antes = storage.borrados;

    await expectLater(
      cliente(_Adapter(status: 401), onUnauthorized: () => cerrada = true).dio.get<dynamic>('/tandas'),
      throwsA(isA<DioException>()),
    );

    expect(cerrada, isTrue);
    expect(storage.borrados, antes + 1);
  });
}
