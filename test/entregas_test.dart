import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/entregas/domain/entities/entrega_entity.dart';
import 'package:tandea/features/entregas/domain/repositories/entrega_repository.dart';
import 'package:tandea/features/entregas/presentation/providers/entrega_provider.dart';
import 'package:tandea/features/entregas/presentation/screens/confirmar_entrega_screen.dart';
import 'package:tandea/features/entregas/presentation/screens/registrar_entrega_screen.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';

const _entrega = EntregaEntity(
  idPayout: 4,
  numero: 1,
  nombreTanda: 'Tanda Oficina',
  transferencia: 200,
  efectivo: 100,
  total: 300,
  confirmada: false,
);

class _FakeRepo implements EntregaRepository {
  Result<EntregaEntity> resultado = const Success(_entrega);
  double? transferencia;
  double? efectivo;
  int confirmadas = 0;
  String? motivo;

  @override
  Future<Result<EntregaEntity>> registrar({
    required int idNumber,
    required double transferencia,
    required double efectivo,
    required ComprobanteArchivo evidencia,
  }) async {
    this.transferencia = transferencia;
    this.efectivo = efectivo;
    return resultado;
  }

  @override
  Future<Result<EntregaEntity>> obtener(int idPayout) async => resultado;

  @override
  Future<Result<EntregaEntity>> confirmar(int idPayout) async {
    confirmadas++;
    return resultado;
  }

  @override
  Future<Result<void>> reportarProblema(int idPayout, String motivo) async {
    this.motivo = motivo;
    return const Success(null);
  }
}

void main() {
  late _FakeRepo repo;
  late EntregaProvider provider;

  final evidencia = ComprobanteArchivo(
    bytes: Uint8List.fromList([1]),
    nombre: 'e.jpg',
    mimeType: 'image/jpeg',
  );

  setUp(() {
    repo = _FakeRepo();
    provider = EntregaProvider(entregaRepository: repo);
  });

  Future<void> pump(WidgetTester tester, Widget pantalla) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider.value(value: provider, child: pantalla),
    ));
    await tester.pumpAndSettle();
  }

  group('Registrar entrega', () {
    const args = RegistrarEntregaArgs(
      idNumber: 5,
      numero: 1,
      nombreReceptor: 'Ana',
      total: 300,
    );

    ElevatedButton boton(WidgetTester tester) => tester.widget<ElevatedButton>(find.descendant(
          of: find.byKey(const Key('btn_registrar_entrega')),
          matching: find.byType(ElevatedButton),
        ));

    testWidgets('exige evidencia y que los montos sumen el total', (tester) async {
      await pump(tester, const RegistrarEntregaScreen(args: args));
      expect(boton(tester).onPressed, isNull, reason: 'falta la evidencia');

      provider.seleccionarEvidencia(evidencia);
      await tester.pump();
      expect(boton(tester).onPressed, isNotNull);

      await tester.enterText(find.byKey(const Key('campo_monto_transferencia')), '100');
      await tester.pump();
      expect(boton(tester).onPressed, isNull, reason: 'la suma no coincide');
      expect(find.textContaining('deben sumar'), findsOneWidget);
    });

    testWidgets('muestra el error del backend y conserva el formulario', (tester) async {
      repo.resultado = const Error(ServerFailure('Aún no es el turno del número #1', statusCode: 409));
      provider.seleccionarEvidencia(evidencia);
      await pump(tester, const RegistrarEntregaScreen(args: args));

      await tester.tap(find.byKey(const Key('btn_registrar_entrega')));
      await tester.pumpAndSettle();

      expect(repo.transferencia, 300);
      expect(find.text('Aún no es el turno del número #1'), findsOneWidget);
    });
  });

  group('Confirmar recepción', () {
    testWidgets('reportar un problema envía el motivo', (tester) async {
      await provider.cargar(4);
      await pump(tester, const ConfirmarEntregaScreen(idPayout: 4));

      await tester.tap(find.byKey(const Key('btn_reportar_problema')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campo_motivo_problema')), 'Faltó dinero');
      await tester.tap(find.byKey(const Key('btn_enviar_problema')));
      await tester.pumpAndSettle();

      expect(repo.motivo, 'Faltó dinero');
      expect(repo.confirmadas, 0);
    });

    testWidgets('una entrega ya confirmada no ofrece confirmar otra vez', (tester) async {
      repo.resultado = const Success(EntregaEntity(
        idPayout: 4,
        numero: 1,
        nombreTanda: 'Tanda Oficina',
        transferencia: 300,
        efectivo: 0,
        total: 300,
        confirmada: true,
      ));
      await provider.cargar(4);
      await pump(tester, const ConfirmarEntregaScreen(idPayout: 4));

      expect(find.byKey(const Key('entrega_confirmada')), findsOneWidget);
      expect(find.byKey(const Key('btn_si_la_recibi')), findsNothing);
    });

    test('confirmar llama al repositorio', () async {
      expect(await provider.confirmar(4), isTrue);
      expect(repo.confirmadas, 1);
    });
  });
}
