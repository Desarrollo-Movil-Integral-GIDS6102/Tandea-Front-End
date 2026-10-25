import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/features/pagos/data/datasources/pago_remote_data_source.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';

/// Nunca se usa: las peticiones ya llevan `Authorization`, así que el interceptor no lee el storage.
class _StorageSinUso extends Fake implements FlutterSecureStorage {}

/// Adaptador HTTP que captura la petición final que Dio enviaría.
class _AdaptadorCaptura implements HttpClientAdapter {
  RequestOptions? peticion;
  int statusCode = 201;
  Object respuesta = <String, dynamic>{
    'idPayment': 45,
    'idNumber': 10,
    'metodoPago': 'hibrido',
    'transferAmount': 600,
    'cashAmount': 400,
    'totalAmount': 1000,
    'status': 'PENDIENTE',
    'confirmedByParticipant': true,
    'confirmedByAdmin': false,
    'ocrVerified': false,
    'ocrDetectedAmount': null,
    'evidenceUrl': 'https://res.cloudinary.com/tandea/comprobantes/pago.png',
    'createdAt': '2026-10-22T16:00:00.000Z',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    peticion = options;
    return ResponseBody.fromString(
      jsonEncode(respuesta),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _comprobante = ComprobanteArchivo(
  bytes: Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
  nombre: 'spei.png',
  mimeType: 'image/png',
);

Map<String, String> _campos(FormData formData) =>
    {for (final campo in formData.fields) campo.key: campo.value};

void main() {
  late _AdaptadorCaptura adaptador;
  late PagoRemoteDataSourceImpl dataSource;

  setUp(() {
    adaptador = _AdaptadorCaptura();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:3000/api/v1',
        headers: const <String, dynamic>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer token-de-prueba',
        },
      ),
    )..httpClientAdapter = adaptador;
    dataSource = PagoRemoteDataSourceImpl(
      apiClient: ApiClient(storage: _StorageSinUso(), dio: dio),
    );
  });

  group('PagoRemoteDataSource.construirFormData', () {
    test('transferencia: idNumber, metodoPago, transferAmount y file', () {
      final formData = PagoRemoteDataSourceImpl.construirFormData(
        RegistrarPagoParams(
          idNumber: 10,
          metodoPago: MetodoPago.transferencia,
          transferAmount: 1500,
          comprobante: _comprobante,
        ),
      );

      expect(_campos(formData), {
        'idNumber': '10',
        'metodoPago': 'transferencia',
        'transferAmount': '1500.00',
      });
      expect(formData.files, hasLength(1));
      final archivo = formData.files.single;
      expect(archivo.key, 'file');
      expect(archivo.value.filename, 'spei.png');
      expect(archivo.value.contentType.toString(), 'image/png');
    });

    test('efectivo sin comprobante: solo cashAmount y ningún archivo', () {
      final formData = PagoRemoteDataSourceImpl.construirFormData(
        const RegistrarPagoParams(
          idNumber: 10,
          metodoPago: MetodoPago.efectivo,
          cashAmount: 1500,
        ),
      );

      expect(_campos(formData), {
        'idNumber': '10',
        'metodoPago': 'efectivo',
        'cashAmount': '1500.00',
      });
      expect(formData.files, isEmpty);
    });

    test('híbrido: ambos montos con 2 decimales exactos (0.1 + 0.2)', () {
      final formData = PagoRemoteDataSourceImpl.construirFormData(
        RegistrarPagoParams(
          idNumber: 10,
          metodoPago: MetodoPago.hibrido,
          transferAmount: 0.1 + 0.2,
          cashAmount: 999.999,
          comprobante: _comprobante,
        ),
      );

      final campos = _campos(formData);
      expect(campos['metodoPago'], 'hibrido');
      expect(campos['transferAmount'], '0.30');
      expect(campos['cashAmount'], '1000.00');
      expect(formData.files.single.key, 'file');
    });
  });

  group('PagoRemoteDataSource.registrarPago', () {
    test('hace POST /pagos como multipart/form-data y parsea la respuesta', () async {
      final pago = await dataSource.registrarPago(
        RegistrarPagoParams(
          idNumber: 10,
          metodoPago: MetodoPago.hibrido,
          transferAmount: 600,
          cashAmount: 400,
          comprobante: _comprobante,
        ),
      );

      final peticion = adaptador.peticion!;
      expect(peticion.method, 'POST');
      expect(peticion.path, '/pagos');
      expect(peticion.data, isA<FormData>());
      expect(peticion.contentType, startsWith('multipart/form-data'));
      expect(_campos(peticion.data as FormData), {
        'idNumber': '10',
        'metodoPago': 'hibrido',
        'transferAmount': '600.00',
        'cashAmount': '400.00',
      });

      expect(pago.idPayment, 45);
      expect(pago.metodoPago, MetodoPago.hibrido);
      expect(pago.totalAmount, 1000);
      expect(pago.status, 'PENDIENTE');
      expect(pago.ocrVerified, isFalse);
    });

    test('409 lanza ServerException con el código y el mensaje del backend', () async {
      adaptador
        ..statusCode = 409
        ..respuesta = <String, dynamic>{
          'statusCode': 409,
          'error': 'Conflict',
          'message': 'Ya existe un pago pendiente o confirmado para el número (turno) 10',
        };

      expect(
        () => dataSource.registrarPago(
          const RegistrarPagoParams(idNumber: 10, metodoPago: MetodoPago.efectivo, cashAmount: 1500),
        ),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', contains('Ya existe un pago')),
        ),
      );
    });

    test('400 sin cuerpo lanza ServerException con mensaje vacío', () async {
      adaptador
        ..statusCode = 400
        ..respuesta = '';

      expect(
        () => dataSource.registrarPago(
          const RegistrarPagoParams(idNumber: 10, metodoPago: MetodoPago.efectivo, cashAmount: 1500),
        ),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', isEmpty),
        ),
      );
    });
  });
}
