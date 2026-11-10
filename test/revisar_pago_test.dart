import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/data/models/pago_model.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/entities/resultado_ocr.dart';
import 'package:tandea/features/pagos/presentation/providers/revisar_pago_provider.dart';
import 'package:tandea/features/pagos/presentation/screens/revisar_pago_screen.dart';

import 'pago_fakes.dart';

/// Híbrido de $1,500: $1,000 por transferencia (con comprobante) y $500 en efectivo.
PagoEntity pagoHibrido({
  double? ocrDetectado = 1000,
  bool ocrVerificado = true,
  String status = 'PENDIENTE',
  bool confirmadoAdmin = false,
  String? evidenceUrl = 'https://res.cloudinary.com/tandea/comprobante.jpg',
  String? motivo,
}) =>
    PagoEntity(
      idPayment: 45,
      idNumber: 10,
      metodoPago: MetodoPago.hibrido,
      transferAmount: 1000,
      cashAmount: 500,
      totalAmount: 1500,
      status: status,
      confirmedByParticipant: true,
      confirmedByAdmin: confirmadoAdmin,
      ocrVerified: ocrVerificado,
      ocrDetectedAmount: ocrDetectado,
      evidenceUrl: evidenceUrl,
      rejectionReason: motivo,
    );

void main() {
  group('ResultadoOcr', () {
    test('coincide si el OCR lo verificó o la diferencia es de \$1 o menos', () {
      expect(ResultadoOcr.de(pagoHibrido()), ResultadoOcr.coincide);
      expect(ResultadoOcr.de(pagoHibrido(ocrDetectado: 1000.8, ocrVerificado: false)), ResultadoOcr.coincide);
    });

    test('no coincide si el monto detectado se aleja del esperado', () {
      expect(ResultadoOcr.de(pagoHibrido(ocrDetectado: 900, ocrVerificado: false)), ResultadoOcr.noCoincide);
    });

    test('sin lectura cuando hay transferencia pero el OCR no detectó monto', () {
      expect(ResultadoOcr.de(pagoHibrido(ocrDetectado: null, ocrVerificado: false)), ResultadoOcr.sinLectura);
    });

    test('no aplica para pagos solo en efectivo', () {
      const efectivo = PagoEntity(
        idPayment: 1,
        idNumber: 1,
        metodoPago: MetodoPago.efectivo,
        transferAmount: 0,
        cashAmount: 1500,
        totalAmount: 1500,
        status: 'PENDIENTE',
      );
      expect(ResultadoOcr.de(efectivo), ResultadoOcr.noAplica);
    });
  });

  test('PagoModel lee el motivo de rechazo', () {
    final pago = PagoModel.fromJson(const {
      'idPayment': 45,
      'idNumber': 10,
      'metodoPago': 'transferencia',
      'transferAmount': 1500,
      'cashAmount': 0,
      'totalAmount': 1500,
      'status': 'RECHAZADO',
      'rejectionReason': 'El monto no coincide',
    });
    expect(pago.estaRechazado, isTrue);
    expect(pago.rejectionReason, 'El monto no coincide');
  });

  group('RevisarPagoProvider', () {
    late FakePagoRepository repo;
    late RevisarPagoProvider provider;

    setUp(() {
      repo = FakePagoRepository()..resultadoObtener = Success(pagoHibrido());
      provider = RevisarPagoProvider(pagoRepository: repo);
    });

    test('confirmar llama al endpoint y reemplaza el pago', () async {
      await provider.cargar(45);
      repo.resultadoRevision = Success(pagoHibrido(status: 'CONFIRMADO', confirmadoAdmin: true));

      final ok = await provider.confirmar();

      expect(ok, isTrue);
      expect(repo.confirmaciones, [45]);
      expect(provider.pago!.estaConfirmado, isTrue);
      expect(provider.puedeRevisar, isFalse);
    });

    test('rechazar envía el motivo sin espacios a los lados', () async {
      await provider.cargar(45);
      repo.resultadoRevision = Success(pagoHibrido(status: 'RECHAZADO', motivo: 'Monto incorrecto'));

      final ok = await provider.rechazar('  Monto incorrecto  ');

      expect(ok, isTrue);
      expect(repo.rechazos, [(45, 'Monto incorrecto')]);
      expect(provider.pago!.estaRechazado, isTrue);
    });

    test('no rechaza con un motivo de menos de 5 caracteres', () async {
      await provider.cargar(45);

      expect(await provider.rechazar('mal'), isFalse);
      expect(repo.rechazos, isEmpty);
    });

    test('bloquea una segunda acción mientras la primera está en curso', () async {
      await provider.cargar(45);
      final completer = Completer<Result<PagoEntity>>();
      repo.revisionPendiente = completer;

      final primera = provider.confirmar();
      expect(provider.accion, AccionRevision.confirmando);
      expect(provider.puedeRevisar, isFalse);
      expect(await provider.rechazar('Otro motivo'), isFalse);

      completer.complete(Success(pagoHibrido(status: 'CONFIRMADO', confirmadoAdmin: true)));
      await primera;
      expect(repo.confirmaciones, [45]);
      expect(repo.rechazos, isEmpty);
      expect(provider.accion, AccionRevision.ninguna);
    });

    test('traduce los errores del backend', () async {
      await provider.cargar(45);
      repo.resultadoRevision = const Error(ServerFailure('Forbidden', statusCode: 403));

      expect(await provider.confirmar(), isFalse);
      expect(provider.errorMessage, 'Solo el organizador de la tanda puede revisar este pago.');
      expect(provider.pago!.estaPendiente, isTrue);
    });
  });

  group('RevisarPagoScreen', () {
    Future<FakePagoRepository> abrir(WidgetTester tester, PagoEntity pago, {double? cuota = 1500}) async {
      final repo = FakePagoRepository()..resultadoObtener = Success(pago);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<RevisarPagoProvider>(
            create: (_) => RevisarPagoProvider(pagoRepository: repo),
            child: RevisarPagoScreen(
              args: RevisarPagoArgs(idPayment: 45, nombreParticipante: 'Ana López', numeroTurno: 3, cuota: cuota),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    Finder enKey(String key, String texto) =>
        find.descendant(of: find.byKey(Key(key)), matching: find.text(texto));

    testWidgets('muestra el comprobante con zoom, el OCR y el desglose', (tester) async {
      await abrir(tester, pagoHibrido());

      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('Turno 3 · Híbrido'), findsOneWidget);

      final visor = tester.widget<InteractiveViewer>(find.byKey(const Key('visor_comprobante')));
      expect(visor.maxScale, greaterThan(1));

      expect(enKey('chip_resultado_ocr', 'Coincide'), findsOneWidget);
      expect(enKey('monto_detectado', r'$1,000.00'), findsOneWidget);
      expect(enKey('monto_esperado', r'$1,000.00'), findsOneWidget);

      await tester.scrollUntilVisible(find.byKey(const Key('desglose_total')), 200);
      expect(enKey('desglose_transferencia', r'$1,000.00'), findsOneWidget);
      expect(enKey('desglose_efectivo', r'$500.00'), findsOneWidget);
      expect(enKey('desglose_total', r'$1,500.00'), findsOneWidget);
    });

    testWidgets('marca el monto que no coincide y la diferencia', (tester) async {
      await abrir(tester, pagoHibrido(ocrDetectado: 900, ocrVerificado: false));

      expect(enKey('chip_resultado_ocr', 'No coincide'), findsOneWidget);
      expect(enKey('monto_detectado', r'$900.00'), findsOneWidget);
      expect(find.textContaining(r'Diferencia de $100.00'), findsOneWidget);
    });

    testWidgets('abre el comprobante en pantalla completa', (tester) async {
      await abrir(tester, pagoHibrido());

      await tester.tap(find.byKey(const Key('btn_comprobante_pantalla_completa')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('visor_comprobante_completo')), findsOneWidget);
    });

    testWidgets('pago en efectivo: sin comprobante ni OCR', (tester) async {
      await abrir(
        tester,
        const PagoEntity(
          idPayment: 45,
          idNumber: 10,
          metodoPago: MetodoPago.efectivo,
          transferAmount: 0,
          cashAmount: 1500,
          totalAmount: 1500,
          status: 'PENDIENTE',
        ),
      );

      expect(find.byKey(const Key('sin_comprobante')), findsOneWidget);
      expect(find.byKey(const Key('comparacion_ocr')), findsNothing);
      expect(find.byKey(const Key('visor_comprobante')), findsNothing);
    });

    testWidgets('Confirmar llama al endpoint y actualiza la pantalla', (tester) async {
      final repo = await abrir(tester, pagoHibrido());
      repo.resultadoRevision = Success(pagoHibrido(status: 'CONFIRMADO', confirmadoAdmin: true));

      final boton = find.byKey(const Key('boton_confirmar_pago'));
      await tester.scrollUntilVisible(boton, 200);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(repo.confirmaciones, [45]);
      expect(find.byKey(const Key('resultado_revision')), findsOneWidget);
      expect(find.byKey(const Key('boton_confirmar_pago')), findsNothing);
      expect(find.byKey(const Key('boton_rechazar_pago')), findsNothing);
      await tester.scrollUntilVisible(find.byKey(const Key('chip_estado_pago')), -200);
      expect(enKey('chip_estado_pago', 'Confirmado'), findsOneWidget);
    });

    testWidgets('Rechazar pide el motivo, llama al endpoint y muestra el resultado', (tester) async {
      final repo = await abrir(tester, pagoHibrido(ocrDetectado: 900, ocrVerificado: false));
      repo.resultadoRevision = Success(
        pagoHibrido(ocrDetectado: 900, ocrVerificado: false, status: 'RECHAZADO', motivo: 'El monto no coincide'),
      );

      final boton = find.byKey(const Key('boton_rechazar_pago'));
      await tester.scrollUntilVisible(boton, 200);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      // El botón del diálogo se habilita con 5 caracteres o más
      final enviar = find.byKey(const Key('boton_enviar_rechazo'));
      expect(tester.widget<FilledButton>(enviar).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('campo_motivo_rechazo')), 'El monto no coincide');
      await tester.pump();
      expect(tester.widget<FilledButton>(enviar).onPressed, isNotNull);

      await tester.tap(enviar);
      await tester.pumpAndSettle();

      expect(repo.rechazos, [(45, 'El monto no coincide')]);
      expect(find.text('Motivo: El monto no coincide'), findsOneWidget);
      expect(find.byKey(const Key('boton_rechazar_pago')), findsNothing);
      await tester.scrollUntilVisible(find.byKey(const Key('chip_estado_pago')), -200);
      expect(enKey('chip_estado_pago', 'Rechazado'), findsOneWidget);
    });

    testWidgets('cancelar el diálogo no rechaza', (tester) async {
      final repo = await abrir(tester, pagoHibrido());

      final boton = find.byKey(const Key('boton_rechazar_pago'));
      await tester.scrollUntilVisible(boton, 200);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.rechazos, isEmpty);
      expect(find.byKey(const Key('boton_rechazar_pago')), findsOneWidget);
    });

    testWidgets('si el backend falla, muestra el error y deja los botones', (tester) async {
      final repo = await abrir(tester, pagoHibrido());
      repo.resultadoRevision = const Error(ServerFailure('El pago ya fue confirmado', statusCode: 409));

      final boton = find.byKey(const Key('boton_confirmar_pago'));
      await tester.scrollUntilVisible(boton, 200);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_error_revision')), findsOneWidget);
      expect(find.text('El pago ya fue confirmado'), findsOneWidget);
      expect(find.byKey(const Key('boton_confirmar_pago')), findsOneWidget);
    });

    testWidgets('pago ya revisado: sin botones', (tester) async {
      await abrir(tester, pagoHibrido(status: 'CONFIRMADO', confirmadoAdmin: true));

      expect(find.byKey(const Key('boton_confirmar_pago')), findsNothing);
      await tester.scrollUntilVisible(find.byKey(const Key('resultado_revision')), 200);
      expect(find.text('Pago confirmado'), findsOneWidget);
    });
  });
}
