import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/features/pagos/data/services/comprobante_service_impl.dart';
import 'package:tandea/features/pagos/domain/entities/origen_imagen.dart';

import 'comprobante_fakes.dart';

void main() {
  late FakeImagePicker fakePicker;
  late FakeImageCompressorService fakeCompressor;
  late FakePermissionService fakePermission;
  late ComprobanteServiceImpl service;

  setUp(() {
    fakePicker = FakeImagePicker();
    fakeCompressor = FakeImageCompressorService();
    fakePermission = FakePermissionService();
    service = ComprobanteServiceImpl(
      imagePicker: fakePicker,
      compressorService: fakeCompressor,
      permissionService: fakePermission,
    );
  });

  group('ComprobanteServiceImpl - Permisos', () {
    test('cámara: solicita permiso de cámara y falla si es denegado', () async {
      fakePermission.permisoCamaraConcedido = false;

      final result = await service.obtenerComprobante(OrigenImagen.camara);

      expect(fakePermission.llamadasCamara, 1);
      expect(fakePicker.llamadas, 0); // No abre el picker si no hay permiso
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('galería: solicita permiso de galería y falla si es denegado', () async {
      fakePermission.permisoGaleriaConcedido = false;

      final result = await service.obtenerComprobante(OrigenImagen.galeria);

      expect(fakePermission.llamadasGaleria, 1);
      expect(fakePicker.llamadas, 0);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('ComprobanteServiceImpl - Cancelación y Validación', () {
    test('si el usuario cancela la selección, devuelve Success(null) sin error', () async {
      fakePicker.archivoARetornar = null;

      final result = await service.obtenerComprobante(OrigenImagen.galeria);

      expect(fakePicker.llamadas, 1);
      expect(fakeCompressor.llamadas, 0);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('si el archivo seleccionado está vacío, devuelve ValidationFailure', () async {
      fakePicker.archivoARetornar = XFile.fromData(
        Uint8List(0),
        name: 'vacio.jpg',
      );

      final result = await service.obtenerComprobante(OrigenImagen.camara);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(fakeCompressor.llamadas, 0);
    });

    test('si la imagen comprimida supera los 10 MB, devuelve ValidationFailure', () async {
      // 10 MB + 1 byte
      final bytesGigantes = Uint8List(10 * 1024 * 1024 + 1);
      fakePicker.archivoARetornar = XFile.fromData(dummyImageBytes, name: 'foto.jpg');
      fakeCompressor.resultadoCompresion = bytesGigantes;

      final result = await service.obtenerComprobante(OrigenImagen.galeria);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('10 MB'));
    });
  });

  group('ComprobanteServiceImpl - Éxito y Compresión', () {
    test('comprime la imagen antes de devolverla y genera nombre y tipo correctos', () async {
      fakePicker.archivoARetornar = XFile.fromData(
        dummyImageBytes,
        name: 'comprobante_banco.png',
      );

      final result = await service.obtenerComprobante(OrigenImagen.camara);

      expect(fakePermission.llamadasCamara, 1);
      expect(fakePicker.llamadas, 1);
      expect(fakePicker.ultimaFuente, ImageSource.camera);
      expect(fakeCompressor.llamadas, 1);
      expect(fakeCompressor.ultimosBytesRecibidos, dummyImageBytes);

      expect(result.isSuccess, isTrue);
      final archivo = result.dataOrNull!;
      expect(archivo.bytes, dummyCompressedBytes);
      expect(archivo.mimeType, 'image/jpeg');
      expect(archivo.nombre.endsWith('.jpg'), isTrue);
    });
  });
}
