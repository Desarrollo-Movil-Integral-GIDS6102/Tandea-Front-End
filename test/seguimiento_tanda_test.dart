import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/data/models/seguimiento_tanda_model.dart';
import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_seguimiento_tanda_usecase.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';
import 'package:tandea/features/tandas/presentation/providers/seguimiento_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/screens/seguimiento_tanda_screen.dart';

class FakeSeguimientoRepository implements TandasRepository {
  Result<SeguimientoTanda> resultado;
  final List<String> consultas = [];

  FakeSeguimientoRepository(this.resultado);

  @override
  Future<Result<SeguimientoTanda>> getSeguimiento(String idTanda) async {
    consultas.add(idTanda);
    return resultado;
  }

  @override
  Future<Result<List<TandaEntity>>> getTandas() => throw UnimplementedError();

  @override
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol}) => throw UnimplementedError();

  @override
  Future<Result<TandaEntity>> getTandaById(String id) => throw UnimplementedError();

  @override
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> tandaData) => throw UnimplementedError();

  @override
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode) => throw UnimplementedError();

  @override
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params) => throw UnimplementedError();
}

ParticipanteSeguimiento participante(int turno, String nombre, EstadoPagoSeguimiento estado) =>
    ParticipanteSeguimiento(idNumber: turno * 10, numeroTurno: turno, nombre: nombre, estadoPago: estado);

/// 5 turnos: 2 pagados, 2 pendientes, 1 atrasado.
final seguimientoDePrueba = SeguimientoTanda(
  idTanda: '7',
  nombreTanda: 'Tanda Oficina',
  vueltaActual: 2,
  totalVueltas: 3,
  cuota: 1000,
  participantes: [
    participante(1, 'Ana López', EstadoPagoSeguimiento.pagado),
    participante(2, 'Beto Ruiz', EstadoPagoSeguimiento.pendiente),
    participante(3, 'Carla Díaz', EstadoPagoSeguimiento.atrasado),
    participante(4, 'Dani Soto', EstadoPagoSeguimiento.pagado),
    participante(5, 'Eva Mora', EstadoPagoSeguimiento.pendiente),
  ],
);

SeguimientoTandaProvider crearProvider(FakeSeguimientoRepository repo) => SeguimientoTandaProvider(
      obtenerSeguimientoUseCase: ObtenerSeguimientoTandaUseCase(repository: repo),
    );

void main() {
  group('SeguimientoTandaModel.fromJson', () {
    test('lee la vuelta actual y el estado de cada participante', () {
      final modelo = SeguimientoTandaModel.fromJson(const {
        'tanda': {'idTanda': 7, 'name': 'Tanda Oficina', 'numRounds': 3, 'contributionAmount': '1000.00'},
        'vueltaActual': 2,
        'participantes': [
          {'idNumber': 21, 'numberValue': 2, 'nombre': 'Beto', 'estadoPago': 'PENDIENTE'},
          {
            'idNumber': 11,
            'numberValue': 1,
            'usuario': {'name': 'Ana', 'lastName': 'López'},
            'pago': {'status': 'CONFIRMADO', 'totalAmount': '1000.00', 'createdAt': '2026-10-20T10:00:00Z'},
          },
          {'idNumber': 31, 'numberValue': 3, 'nombre': 'Carla', 'estadoPago': 'ATRASADO'},
          {'idNumber': 41, 'numberValue': 4, 'isDeadNumber': true},
        ],
      });

      expect(modelo.idTanda, '7');
      expect(modelo.nombreTanda, 'Tanda Oficina');
      expect(modelo.vueltaActual, 2);
      expect(modelo.totalVueltas, 3);
      expect(modelo.cuota, 1000);
      // Ordenados por número de turno
      expect(modelo.participantes.map((p) => p.numeroTurno), [1, 2, 3, 4]);
      expect(modelo.participantes[0].nombre, 'Ana López');
      expect(modelo.participantes[0].estadoPago, EstadoPagoSeguimiento.pagado);
      expect(modelo.participantes[0].montoPagado, 1000);
      expect(modelo.participantes[0].fechaPago, isNotNull);
      expect(modelo.participantes[1].estadoPago, EstadoPagoSeguimiento.pendiente);
      expect(modelo.participantes[2].estadoPago, EstadoPagoSeguimiento.atrasado);
      expect(modelo.participantes[3].isDeadNumber, isTrue);
      expect(modelo.participantes[3].nombre, 'Número muerto');
    });

    test('un pago rechazado o sin estado cuenta como pendiente', () {
      expect(EstadoPagoSeguimiento.fromValor('RECHAZADO'), EstadoPagoSeguimiento.pendiente);
      expect(EstadoPagoSeguimiento.fromValor(null), EstadoPagoSeguimiento.pendiente);
      expect(EstadoPagoSeguimiento.fromValor('pagado'), EstadoPagoSeguimiento.pagado);
    });
  });

  group('SeguimientoTandaProvider', () {
    test('carga el seguimiento de la tanda y calcula el progreso de pagos confirmados', () async {
      final repo = FakeSeguimientoRepository(Success(seguimientoDePrueba));
      final provider = crearProvider(repo);

      await provider.cargar('7');

      expect(repo.consultas, ['7']);
      expect(provider.cantidadFiltrados, 5);
      expect(provider.totalPagados, 2);
      expect(provider.progreso, closeTo(0.4, 0.0001));
    });

    test('filtra por Pagados, Pendientes y Atrasados', () async {
      final provider = crearProvider(FakeSeguimientoRepository(Success(seguimientoDePrueba)));
      await provider.cargar('7');

      provider.cambiarFiltro(FiltroSeguimiento.pagados);
      expect(provider.participantesFiltrados.map((p) => p.nombre), ['Ana López', 'Dani Soto']);

      provider.cambiarFiltro(FiltroSeguimiento.pendientes);
      expect(provider.participantesFiltrados.map((p) => p.nombre), ['Beto Ruiz', 'Eva Mora']);

      provider.cambiarFiltro(FiltroSeguimiento.atrasados);
      expect(provider.participantesFiltrados.map((p) => p.nombre), ['Carla Díaz']);

      provider.cambiarFiltro(FiltroSeguimiento.todos);
      expect(provider.cantidadFiltrados, 5);
    });

    test('el filtro se conserva al recargar', () async {
      final repo = FakeSeguimientoRepository(Success(seguimientoDePrueba));
      final provider = crearProvider(repo);
      await provider.cargar('7');
      provider.cambiarFiltro(FiltroSeguimiento.atrasados);

      await provider.cargar('7');

      expect(provider.filtro, FiltroSeguimiento.atrasados);
      expect(provider.cantidadFiltrados, 1);
    });

    test('sin participantes el progreso es 0', () async {
      final provider = crearProvider(FakeSeguimientoRepository(const Success(
        SeguimientoTanda(idTanda: '1', nombreTanda: 'Vacía', vueltaActual: 1, cuota: 100, participantes: []),
      )));
      await provider.cargar('1');

      expect(provider.progreso, 0);
    });

    test('expone el mensaje de error del backend', () async {
      final provider = crearProvider(
        FakeSeguimientoRepository(const Error(ServerFailure('No eres organizador', statusCode: 403))),
      );
      await provider.cargar('7');

      expect(provider.isError, isTrue);
      expect(provider.errorMessage, 'No eres organizador');
    });
  });

  group('SeguimientoTandaScreen', () {
    Future<FakeSeguimientoRepository> abrirPanel(WidgetTester tester, Result<SeguimientoTanda> resultado) async {
      final repo = FakeSeguimientoRepository(resultado);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SeguimientoTandaProvider>(
            create: (_) => crearProvider(repo),
            child: const SeguimientoTandaScreen(idTanda: '7'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('muestra a cada participante con su estado y la barra de progreso', (tester) async {
      final repo = await abrirPanel(tester, Success(seguimientoDePrueba));

      expect(repo.consultas, ['7']);
      expect(find.text('Tanda Oficina'), findsOneWidget);
      expect(find.text('Vuelta 2 de 3'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('2 de 5 pagos confirmados'), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(find.byKey(const Key('barra_progreso_seguimiento')));
      expect(barra.value, closeTo(0.4, 0.0001));

      for (final p in seguimientoDePrueba.participantes) {
        expect(find.byKey(Key('fila_seguimiento_${p.idNumber}')), findsOneWidget);
      }
      expect(find.text('Todos (5)'), findsOneWidget);
      expect(find.text('Pagados (2)'), findsOneWidget);
      expect(find.text('Pendientes (2)'), findsOneWidget);
      expect(find.text('Atrasados (1)'), findsOneWidget);
    });

    testWidgets('las pestañas filtran la lista', (tester) async {
      await abrirPanel(tester, Success(seguimientoDePrueba));

      await tester.tap(find.byKey(const Key('tab_seguimiento_pagados')));
      await tester.pumpAndSettle();
      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('Dani Soto'), findsOneWidget);
      expect(find.text('Beto Ruiz'), findsNothing);
      expect(find.text('Carla Díaz'), findsNothing);

      await tester.tap(find.byKey(const Key('tab_seguimiento_atrasados')));
      await tester.pumpAndSettle();
      expect(find.text('Carla Díaz'), findsOneWidget);
      expect(find.text('Ana López'), findsNothing);

      await tester.tap(find.byKey(const Key('tab_seguimiento_pendientes')));
      await tester.pumpAndSettle();
      expect(find.text('Beto Ruiz'), findsOneWidget);
      expect(find.text('Eva Mora'), findsOneWidget);
      expect(find.text('Carla Díaz'), findsNothing);

      // La barra no depende de la pestaña
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('pestaña sin resultados muestra mensaje vacío', (tester) async {
      await abrirPanel(
        tester,
        Success(SeguimientoTanda(
          idTanda: '7',
          nombreTanda: 'Tanda Oficina',
          vueltaActual: 1,
          cuota: 1000,
          participantes: [participante(1, 'Ana López', EstadoPagoSeguimiento.pagado)],
        )),
      );

      await tester.tap(find.byKey(const Key('tab_seguimiento_atrasados')));
      await tester.pumpAndSettle();

      expect(find.text('Nadie está atrasado. ¡Todo en orden!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('error: muestra mensaje y permite reintentar', (tester) async {
      final repo = await abrirPanel(tester, const Error(NetworkFailure('Sin conexión')));

      expect(find.text('Sin conexión'), findsOneWidget);

      repo.resultado = Success(seguimientoDePrueba);
      await tester.tap(find.byKey(const Key('btn_reintentar_seguimiento')));
      await tester.pumpAndSettle();

      expect(repo.consultas, ['7', '7']);
      expect(find.text('2 de 5 pagos confirmados'), findsOneWidget);
    });
  });
}
