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
  Future<Result<TandaEntity>> iniciarTanda(String id) => throw UnimplementedError();

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
  group('SeguimientoTandaModel.fromJson: turnoVigente (AP-10)', () {
    const base = <String, dynamic>{
      'tanda': {'idTanda': 3, 'name': 'Oficina', 'numRounds': 1, 'contributionAmount': 100},
      'vueltaActual': 1,
      'cuota': 100,
      'participantes': <dynamic>[],
    };

    test('lee el monto a entregar con el descuento por cuotas no confirmadas', () {
      final modelo = SeguimientoTandaModel.fromJson(const {
        ...base,
        'turnoVigente': {
          'idNumber': 7,
          'numberValue': 1,
          'estadoTurno': 'EN_RIESGO',
          'totalTurno': 300,
          'descuento': 100,
          'montoAEntregar': 200,
          'cuotasNoConfirmadas': 1,
          'bloqueado': false,
        },
      });

      final turno = modelo.turnoVigente!;
      expect(turno.idNumber, 7);
      expect(turno.numeroTurno, 1);
      expect(turno.estadoTurno, 'EN_RIESGO');
      expect(turno.totalTurno, 300);
      expect(turno.descuento, 100);
      expect(turno.montoAEntregar, 200);
      expect(turno.cuotasNoConfirmadas, 1);
      expect(turno.motivoBloqueo, isNull);
    });

    test('un turno bloqueado explica por qué no se puede entregar', () {
      final modelo = SeguimientoTandaModel.fromJson(const {
        ...base,
        'turnoVigente': {
          'idNumber': 7,
          'numberValue': 1,
          'totalTurno': 300,
          'montoAEntregar': 100,
          'bloqueado': true,
        },
      });

      expect(modelo.turnoVigente!.motivoBloqueo, contains('en riesgo'));
    });

    test('sin ningún pago confirmado no hay nada que entregar', () {
      final modelo = SeguimientoTandaModel.fromJson(const {
        ...base,
        'turnoVigente': {'idNumber': 7, 'numberValue': 1, 'totalTurno': 300, 'montoAEntregar': 0},
      });

      expect(modelo.turnoVigente!.motivoBloqueo, contains('Aún no hay pagos confirmados'));
    });

    test('si el backend no manda turnoVigente (o es null) queda en null', () {
      expect(SeguimientoTandaModel.fromJson(base).turnoVigente, isNull);
      expect(SeguimientoTandaModel.fromJson(const {...base, 'turnoVigente': null}).turnoVigente, isNull);
    });

    test('lee numeroMuerto, estadoTurno y cubiertoPorNumeroMuerto de cada participante', () {
      final modelo = SeguimientoTandaModel.fromJson(const {
        'tanda': {'idTanda': 3, 'name': 'Oficina', 'numRounds': 1, 'contributionAmount': 100},
        'vueltaActual': 1,
        'cuota': 100,
        'numeroMuerto': {
          'idNumber': 100,
          'numberValue': 0,
          'estadoTurno': 'PENDIENTE',
          'pagosCubiertos': 1,
          'montoCubierto': 100,
        },
        'participantes': [
          {
            'idNumber': 11,
            'numberValue': 1,
            'nombre': 'Ana',
            'estadoPago': 'CONFIRMADO',
            'estadoTurno': 'PENDIENTE',
            'cubiertoPorNumeroMuerto': false,
          },
          {
            'idNumber': 12,
            'numberValue': 2,
            'nombre': 'Beto',
            'estadoPago': 'VENCIDO',
            'estadoTurno': 'EN_RIESGO',
            'cubiertoPorNumeroMuerto': false,
          },
          {
            'idNumber': 13,
            'numberValue': 3,
            'nombre': 'Carla',
            'estadoPago': 'CONFIRMADO',
            'estadoTurno': 'PENDIENTE',
            'cubiertoPorNumeroMuerto': true,
            'montoPagado': 100,
          },
        ],
      });

      expect(modelo.numeroMuerto, isNotNull);
      expect(modelo.numeroMuerto!.idNumber, 100);
      expect(modelo.numeroMuerto!.numeroTurno, 0);
      expect(modelo.numeroMuerto!.pagosCubiertos, 1);
      expect(modelo.numeroMuerto!.montoCubierto, 100);
      expect(modelo.numeroMuerto!.fueUsado, isTrue);

      expect(modelo.participantes[0].estadoTurnoChip, EstadoTurnoSeguimiento.alDia);
      expect(modelo.participantes[0].estadoTurnoChip.etiqueta, 'Al día');

      expect(modelo.participantes[1].estadoTurno, 'EN_RIESGO');
      expect(modelo.participantes[1].estadoTurnoChip, EstadoTurnoSeguimiento.enRiesgo);
      expect(modelo.participantes[1].estadoTurnoChip.etiqueta, 'En riesgo');

      expect(modelo.participantes[2].cubiertoPorNumeroMuerto, isTrue);
      expect(modelo.participantes[2].estadoTurnoChip, EstadoTurnoSeguimiento.cubierto);
      expect(modelo.participantes[2].estadoTurnoChip.etiqueta, 'Cubierto');
    });
  });

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
      // Pantalla alta para que la lista dibuje las 5 filas debajo de la tarjeta de progreso
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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

    testWidgets('muestra la tarjeta verde de Número Muerto y los chips de estado del turno (Al día, En riesgo, Cubierto)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const seguimientoConMuerto = SeguimientoTanda(
        idTanda: '7',
        nombreTanda: 'Tanda con Respaldo',
        vueltaActual: 1,
        totalVueltas: 1,
        cuota: 500,
        numeroMuerto: NumeroMuertoSeguimiento(
          idNumber: 100,
          numeroTurno: 0,
          estadoTurno: 'PENDIENTE',
          pagosCubiertos: 1,
          montoCubierto: 500,
        ),
        participantes: [
          ParticipanteSeguimiento(
            idNumber: 10,
            numeroTurno: 1,
            nombre: 'Ana López',
            estadoPago: EstadoPagoSeguimiento.pagado,
            estadoTurno: 'PENDIENTE',
            montoPagado: 500,
          ),
          ParticipanteSeguimiento(
            idNumber: 20,
            numeroTurno: 2,
            nombre: 'Beto Ruiz',
            estadoPago: EstadoPagoSeguimiento.atrasado,
            estadoTurno: 'EN_RIESGO',
          ),
          ParticipanteSeguimiento(
            idNumber: 30,
            numeroTurno: 3,
            nombre: 'Carla Díaz',
            estadoPago: EstadoPagoSeguimiento.pagado,
            estadoTurno: 'PENDIENTE',
            cubiertoPorNumeroMuerto: true,
            montoPagado: 500,
          ),
        ],
      );

      await abrirPanel(tester, const Success(seguimientoConMuerto));

      expect(find.byKey(const Key('fila_numero_muerto_seguimiento')), findsOneWidget);
      expect(find.text('Número Muerto'), findsOneWidget);
      expect(find.textContaining('Cubrió 1 pago'), findsOneWidget);

      expect(find.byKey(const Key('chip_estado_turno_10')), findsOneWidget);
      expect(find.byKey(const Key('chip_estado_turno_20')), findsOneWidget);
      expect(find.byKey(const Key('chip_estado_turno_30')), findsOneWidget);
      expect(find.text('Al día'), findsOneWidget);
      expect(find.text('En riesgo'), findsOneWidget);
      expect(find.text('Cubierto'), findsNWidgets(2));
    });
  });
}
