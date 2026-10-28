import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/data/models/tanda_model.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';
import 'package:tandea/features/tandas/presentation/providers/tanda_detalle_provider.dart';
import 'package:tandea/features/tandas/presentation/screens/tanda_detalle_screen.dart';

class _FakeRepo implements TandasRepository {
  TandaEntity tanda;
  bool iniciada = false;

  _FakeRepo(this.tanda);

  @override
  Future<Result<TandaEntity>> getTandaById(String id) async => Success(tanda);

  @override
  Future<Result<TandaEntity>> iniciarTanda(String id) async {
    iniciada = true;
    tanda = tanda.copyWith(estado: 'ACTIVA');
    return Success(tanda);
  }

  @override
  Future<Result<List<TandaEntity>>> getTandas() async => const Success([]);
  @override
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol}) async => const Success([]);
  @override
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> data) async => Success(tanda);
  @override
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode) async => Success(tanda);
  @override
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params) async =>
      Success(UnirseTandaResult(tanda: tanda, numeroAsignado: 1));
}

/// Respuesta de `GET /tandas/:id` para un usuario con los números #1 y #3.
TandaEntity _detalle({required String status, List<int> disponibles = const []}) =>
    TandaModel.fromJson({
      'idTanda': 7,
      'name': 'Tanda Oficina',
      'contributionAmount': 500,
      'numParticipants': 3,
      'status': status,
      'inviteCode': 'TND-ABC123',
      'hasDeadNumber': false,
      'rolUsuario': 'AMBOS',
      'numerosDisponibles': disponibles,
      'participantes': [
        {'idNumber': 11, 'numberValue': 1, 'roundNumber': 1, 'idUser': 5, 'isDeadNumber': false, 'userName': 'Ana'},
        {'idNumber': 13, 'numberValue': 3, 'roundNumber': 1, 'idUser': 5, 'isDeadNumber': false, 'userName': 'Ana'},
      ],
      'misNumeros': [
        {'idNumber': 11, 'numberValue': 1, 'roundNumber': 1, 'isDeadNumber': false},
        {'idNumber': 13, 'numberValue': 3, 'roundNumber': 1, 'isDeadNumber': false},
      ],
    });

Future<_FakeRepo> _pump(WidgetTester tester, TandaEntity tanda) async {
  final repo = _FakeRepo(tanda);
  // Pantalla alta para que la lista construya todas las secciones
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: ChangeNotifierProvider(
      create: (_) => TandaDetalleProvider(tandasRepository: repo)..cargar('7'),
      child: const TandaDetalleScreen(idTanda: '7'),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('muestra el detalle y mis números aunque la tanda no haya iniciado', (tester) async {
    await _pump(tester, _detalle(status: 'PENDIENTE', disponibles: [2]));

    expect(find.byKey(const Key('mi_numero_1')), findsOneWidget);
    expect(find.byKey(const Key('mi_numero_3')), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget); // el #2

    final pagar = tester.widget<ElevatedButton>(find.byKey(const Key('btn_pagar_numero_1')));
    expect(pagar.onPressed, isNull, reason: 'el pago se habilita hasta que el organizador inicia');
    expect(find.byKey(const Key('btn_apartar_numeros')), findsOneWidget);
  });

  testWidgets('el organizador no puede iniciar mientras falten números', (tester) async {
    await _pump(tester, _detalle(status: 'PENDIENTE', disponibles: [2]));

    final iniciar = tester.widget<ElevatedButton>(find.byKey(const Key('btn_iniciar_tanda')));
    expect(iniciar.onPressed, isNull);
    expect(find.textContaining('Faltan 1 números'), findsOneWidget);
  });

  testWidgets('al iniciar la tanda se habilita el pago de cada número', (tester) async {
    final repo = await _pump(tester, _detalle(status: 'PENDIENTE'));

    await tester.ensureVisible(find.byKey(const Key('btn_iniciar_tanda')));
    await tester.tap(find.byKey(const Key('btn_iniciar_tanda')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_confirmar_iniciar_tanda')));
    await tester.pumpAndSettle();

    expect(repo.iniciada, isTrue);
    final pagar = tester.widget<ElevatedButton>(find.byKey(const Key('btn_pagar_numero_3')));
    expect(pagar.onPressed, isNotNull);
    expect(find.byKey(const Key('btn_iniciar_tanda')), findsNothing);
    expect(find.byKey(const Key('btn_apartar_numeros')), findsNothing);
  });
}
