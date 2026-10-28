import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';

import 'pago_fakes.dart';

void main() {
  late FakePagoRepository repository;
  late PagoProvider provider;
  late List<EstadoCarga> estados;

  setUp(() {
    repository = FakePagoRepository();
    provider = PagoProvider(pagoRepository: repository);
    estados = [];
    provider.addListener(() => estados.add(provider.estado));
  });

  Future<bool> registrar() => provider.registrarPago(idNumber: 10, cuota: 1500);

  group('PagoProvider.registrarPago - éxito', () {
    test('transferencia: envía la cuota como transferAmount y pasa a éxito', () async {
      final ok = await registrar();

      expect(ok, isTrue);
      expect(estados, [EstadoCarga.cargando, EstadoCarga.exito]);
      expect(provider.estado, EstadoCarga.exito);
      expect(provider.errorMessage, isNull);
      expect(provider.pagoRegistrado, pagoRegistradoDePrueba);

      final params = repository.ultimaLlamada!;
      expect(params.idNumber, 10);
      expect(params.metodoPago, MetodoPago.transferencia);
      expect(params.transferAmount, 1500);
      expect(params.cashAmount, isNull);
    });

    test('efectivo: envía la cuota como cashAmount', () async {
      provider.seleccionarMetodo(MetodoPago.efectivo);

      await registrar();

      final params = repository.ultimaLlamada!;
      expect(params.metodoPago, MetodoPago.efectivo);
      expect(params.cashAmount, 1500);
      expect(params.transferAmount, isNull);
    });

    test('híbrido: envía los montos capturados por el usuario', () async {
      provider
        ..seleccionarMetodo(MetodoPago.hibrido)
        ..actualizarMontoTransferencia('1000.50')
        ..actualizarMontoEfectivo('499.50');

      await registrar();

      final params = repository.ultimaLlamada!;
      expect(params.metodoPago, MetodoPago.hibrido);
      expect(params.transferAmount, 1000.50);
      expect(params.cashAmount, 499.50);
    });
  });

  group('PagoProvider.registrarPago - errores', () {
    test('400 sin detalle: muestra "Revisa los montos o el comprobante."', () async {
      repository.resultado = const Error(ServerFailure('', statusCode: 400));

      final ok = await registrar();

      expect(ok, isFalse);
      expect(estados, [EstadoCarga.cargando, EstadoCarga.error]);
      expect(provider.errorMessage, 'Revisa los montos o el comprobante.');
    });

    test('400/422 con detalle del backend: muestra el detalle', () async {
      repository.resultado = const Error(
        ServerFailure('El comprobante debe ser un archivo JPG, PNG o PDF', statusCode: 400),
      );
      await registrar();
      expect(provider.errorMessage, 'El comprobante debe ser un archivo JPG, PNG o PDF');

      repository.resultado = const Error(
        ServerFailure('La suma de efectivo y transferencia no coincide', statusCode: 422),
      );
      await registrar();
      expect(provider.errorMessage, 'La suma de efectivo y transferencia no coincide');
    });

    test('409: "Este pago ya fue registrado."', () async {
      repository.resultado = const Error(ServerFailure('Ya existe un pago', statusCode: 409));

      await registrar();

      expect(provider.estado, EstadoCarga.error);
      expect(provider.errorMessage, 'Este pago ya fue registrado.');
    });

    test('403: "No puedes registrar pagos en este número."', () async {
      repository.resultado = const Error(ServerFailure('Forbidden', statusCode: 403));

      await registrar();

      expect(provider.errorMessage, 'No puedes registrar pagos en este número.');
    });

    test('sin conexión: "No pudimos enviar tu pago. Intenta de nuevo."', () async {
      repository.resultado = const Error(NetworkFailure('Sin conexión a internet.'));

      final ok = await registrar();

      expect(ok, isFalse);
      expect(estados, [EstadoCarga.cargando, EstadoCarga.error]);
      expect(provider.errorMessage, 'No pudimos enviar tu pago. Intenta de nuevo.');
    });

    test('5xx: "No pudimos enviar tu pago. Intenta de nuevo."', () async {
      repository.resultado = const Error(ServerFailure('Internal Server Error', statusCode: 500));

      await registrar();

      expect(provider.errorMessage, 'No pudimos enviar tu pago. Intenta de nuevo.');
    });

    test('un nuevo intento limpia el error anterior al empezar', () async {
      repository.resultado = const Error(NetworkFailure());
      await registrar();
      expect(provider.errorMessage, isNotNull);

      repository.resultado = const Success(pagoRegistradoDePrueba);
      await registrar();

      expect(provider.errorMessage, isNull);
      expect(provider.estado, EstadoCarga.exito);
    });
  });

  group('PagoProvider - estado de envío', () {
    test('enviando es true mientras espera y se ignora un segundo envío', () async {
      repository.pendiente = Completer<Result<PagoEntity>>();

      final primerEnvio = registrar();
      expect(provider.enviando, isTrue);
      expect(provider.estado, EstadoCarga.cargando);

      final segundoEnvio = await registrar();
      expect(segundoEnvio, isFalse);
      expect(repository.llamadas, hasLength(1));

      repository.pendiente!.complete(const Success(pagoRegistradoDePrueba));
      expect(await primerEnvio, isTrue);
      expect(provider.enviando, isFalse);
    });

    test('cambiar de método limpia el mensaje de error', () async {
      repository.resultado = const Error(ServerFailure('', statusCode: 409));
      await registrar();
      expect(provider.errorMessage, isNotNull);

      provider.seleccionarMetodo(MetodoPago.efectivo);

      expect(provider.errorMessage, isNull);
    });
  });

  group('PagoProvider - validación antes de enviar', () {
    test('híbrido: la suma exacta en centavos es válida (0.10 + 0.20 = 0.30)', () {
      provider.seleccionarMetodo(MetodoPago.hibrido);
      provider.actualizarMontoTransferencia('0.10');
      provider.actualizarMontoEfectivo('0.20');

      expect(provider.sumaValida(0.30), isTrue);
    });

    test('híbrido: suma mayor, menor o con un monto en cero no es válida', () {
      provider.seleccionarMetodo(MetodoPago.hibrido);

      provider.actualizarMontoTransferencia('1000');
      provider.actualizarMontoEfectivo('600');
      expect(provider.sumaValida(1500), isFalse);

      provider.actualizarMontoEfectivo('400');
      expect(provider.sumaValida(1500), isFalse);

      provider.actualizarMontoTransferencia('1500');
      provider.actualizarMontoEfectivo('0');
      expect(provider.sumaValida(1500), isFalse);
    });

    test('transferencia exige comprobante; efectivo no', () {
      expect(provider.puedeEnviar(1500), isFalse);

      provider.seleccionarComprobante(comprobanteDePrueba);
      expect(provider.puedeEnviar(1500), isTrue);

      provider.seleccionarComprobante(null);
      provider.seleccionarMetodo(MetodoPago.efectivo);
      expect(provider.puedeEnviar(1500), isTrue);
    });
  });
}
