import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/origen_imagen.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';

import 'comprobante_fakes.dart';
import 'pago_fakes.dart';

void main() {
  late FakePagoRepository fakeRepo;
  late FakeComprobanteService fakeComprobanteService;
  late FakeSeleccionarComprobanteUseCase fakeUseCase;
  late PagoProvider provider;

  setUp(() {
    fakeRepo = FakePagoRepository();
    fakeComprobanteService = FakeComprobanteService();
    fakeUseCase = FakeSeleccionarComprobanteUseCase(service: fakeComprobanteService);
    provider = PagoProvider(
      pagoRepository: fakeRepo,
      seleccionarComprobanteUseCase: fakeUseCase,
    );
  });

  group('PagoProvider - Captura y Selección de Comprobante', () {
    test('captura exitosa: actualiza comprobante y gestiona estados de carga', () async {
      expect(provider.comprobante, isNull);
      expect(provider.procesandoComprobante, isFalse);

      final future = provider.capturarComprobante(OrigenImagen.camara);
      expect(provider.procesandoComprobante, isTrue);

      await future;
      expect(provider.procesandoComprobante, isFalse);
      expect(provider.comprobante, comprobanteDePrueba);
      expect(provider.errorMessage, isNull);
      expect(fakeComprobanteService.ultimoOrigen, OrigenImagen.camara);
    });

    test('cancelación: no sobrescribe comprobante previo ni genera mensaje de error', () async {
      // Estado inicial con comprobante previo
      provider.seleccionarComprobante(comprobanteDePrueba);
      expect(provider.comprobante, comprobanteDePrueba);

      // Simula que el usuario cancela en el selector
      fakeComprobanteService.resultado = const Success(null);

      await provider.capturarComprobante(OrigenImagen.galeria);

      expect(provider.procesandoComprobante, isFalse);
      expect(provider.comprobante, comprobanteDePrueba); // Se conserva
      expect(provider.errorMessage, isNull);
    });

    test('error de captura o permisos: registra errorMessage y libera procesando', () async {
      fakeComprobanteService.resultado = const Error(
        PermissionFailure('Permiso de cámara no concedido.'),
      );

      await provider.capturarComprobante(OrigenImagen.camara);

      expect(provider.procesandoComprobante, isFalse);
      expect(provider.comprobante, isNull);
      expect(provider.errorMessage, 'Permiso de cámara no concedido.');
    });

    test('eliminarComprobante limpia la selección actual', () {
      provider.seleccionarComprobante(comprobanteDePrueba);
      expect(provider.comprobante, isNotNull);

      provider.eliminarComprobante();
      expect(provider.comprobante, isNull);
    });

    test('reemplazar comprobante sustituye el anterior por el nuevo', () async {
      final comprobanteNuevo = ComprobanteArchivo(
        bytes: Uint8List.fromList([1, 2, 3]),
        nombre: 'nuevo.jpg',
        mimeType: 'image/jpeg',
      );
      provider.seleccionarComprobante(comprobanteDePrueba);
      expect(provider.comprobante?.nombre, 'comprobante_test.jpg');

      fakeComprobanteService.resultado = Success(comprobanteNuevo);
      await provider.capturarComprobante(OrigenImagen.galeria);

      expect(provider.comprobante?.nombre, 'nuevo.jpg');
    });
  });

  group('PagoProvider - Bloqueo de envío inválido o en proceso', () {
    test('no permite registrar mientras la imagen se está procesando', () async {
      // Simula que la captura o compresión está en curso
      final future = provider.capturarComprobante(OrigenImagen.camara);
      expect(provider.procesandoComprobante, isTrue);
      expect(provider.puedeRegistrar, isFalse);

      final enviado = await provider.registrarPago(idNumber: 10, cuota: 1500);
      expect(enviado, isFalse);
      expect(fakeRepo.llamadas, isEmpty);

      await future;
    });

    test('no permite registrar si el comprobante tiene bytes vacíos', () async {
      provider.seleccionarComprobante(
        ComprobanteArchivo(
          bytes: Uint8List(0),
          nombre: 'vacio.jpg',
          mimeType: 'image/jpeg',
        ),
      );

      final enviado = await provider.registrarPago(idNumber: 10, cuota: 1500);

      expect(enviado, isFalse);
      expect(fakeRepo.llamadas, isEmpty);
      expect(provider.errorMessage, contains('vacío'));
    });
  });
}
