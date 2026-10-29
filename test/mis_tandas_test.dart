import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/pagos/presentation/screens/registrar_pago_screen.dart';
import 'package:tandea/features/tandas/data/models/tanda_model.dart';
import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/features/tandas/presentation/screens/mis_tandas_organizador_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/mis_tandas_participante_screen.dart';
import 'package:tandea/features/tandas/presentation/widgets/mis_tandas_list_view.dart';
import 'package:tandea/features/tandas/presentation/widgets/tanda_card_item.dart';

import 'tandas_repository_fake.dart';

class MockTandasRepository implements TandasRepository {
  Result<List<TandaEntity>>? getMisTandasResult;
  String? lastQueriedRol;

  @override
  Future<Result<List<TandaEntity>>> getTandas() async => const Success([]);

  @override
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol}) async {
    lastQueriedRol = rol;
    return getMisTandasResult ??
        const Success([
          TandaEntity(
            id: '1',
            nombre: 'Tanda Universitaria',
            monto: 1000.0,
            totalParticipantes: 5,
            periodo: 'quincenal',
            estado: 'ACTIVA',
            inviteCode: 'TND-UNI1',
            indicadorPago: IndicadorPago.alDia,
          ),
          TandaEntity(
            id: '2',
            nombre: 'Tanda Familiar Diciembre',
            monto: 2500.0,
            totalParticipantes: 10,
            periodo: 'mensual',
            estado: 'PENDIENTE',
            inviteCode: 'TND-FAM2',
            indicadorPago: IndicadorPago.pendiente,
          ),
        ]);
  }

  @override
  Future<Result<TandaEntity>> getTandaById(String id) async =>
      const Success(TandaEntity(
        id: '1',
        nombre: 'Mock',
        monto: 100,
        totalParticipantes: 5,
        periodo: 'quincenal',
        estado: 'ACTIVA',
      ));

  @override
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> data) async =>
      const Success(TandaEntity(
        id: '1',
        nombre: 'Mock',
        monto: 100,
        totalParticipantes: 5,
        periodo: 'quincenal',
        estado: 'ACTIVA',
      ));

  @override
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode) async =>
      const Success(TandaEntity(
        id: '1',
        nombre: 'Mock',
        monto: 100,
        totalParticipantes: 5,
        periodo: 'quincenal',
        estado: 'ACTIVA',
      ));

  @override
  Future<Result<TandaEntity>> iniciarTanda(String id) async => getTandaById(id);

  @override
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params) async =>
      const Success(UnirseTandaResult(
        tanda: TandaEntity(
          id: '1',
          nombre: 'Mock',
          monto: 100,
          totalParticipantes: 5,
          periodo: 'quincenal',
          estado: 'ACTIVA',
        ),
        numeroAsignado: 1,
      ));

  @override
  Future<Result<SeguimientoTanda>> getSeguimiento(String idTanda) async =>
      const Error(ServerFailure('No implementado'));
}

void main() {
  late MockTandasRepository mockRepo;
  late TandasProvider provider;

  setUp(() {
    mockRepo = MockTandasRepository();
    provider = TandasProvider(tandasRepository: mockRepo);
  });

  group('TandasProvider - Mis Tandas y Manejo de Estado', () {
    test('estado inicial está limpio', () {
      expect(provider.tandas, isEmpty);
      expect(provider.estado, equals(EstadoCarga.inicial));
      expect(provider.errorMessage, isNull);
      expect(provider.rolSeleccionado, equals('participante'));
    });

    test('fetchMisTandas consulta con rol participante y almacena tandas con estado exito', () async {
      await provider.fetchMisTandas(rol: 'participante');

      expect(mockRepo.lastQueriedRol, equals('participante'));
      expect(provider.estado, equals(EstadoCarga.exito));
      expect(provider.tandas.length, equals(2));
      expect(provider.obtenerTandaEn(0).nombre, equals('Tanda Universitaria'));
      expect(provider.obtenerTandaEn(0).indicadorPago, equals(IndicadorPago.alDia));
      expect(provider.obtenerTandaEn(1).indicadorPago, equals(IndicadorPago.pendiente));
    });

    test('fetchMisTandas con rol organizador consulta correctamente', () async {
      await provider.fetchMisTandas(rol: 'organizador');

      expect(mockRepo.lastQueriedRol, equals('organizador'));
      expect(provider.rolSeleccionado, equals('organizador'));
    });

    test('fetchMisTandas maneja error del backend y establece mensaje de error', () async {
      mockRepo.getMisTandasResult = const Error(
        ServerFailure('Error al consultar mis tandas', statusCode: 500),
      );

      await provider.fetchMisTandas(rol: 'participante');

      expect(provider.estado, equals(EstadoCarga.error));
      expect(provider.errorMessage, equals('Error al consultar mis tandas'));
      expect(provider.tandas, isEmpty);
    });

    test('obtenerTandaEn lanza RangeError si el índice está fuera de rango', () {
      expect(() => provider.obtenerTandaEn(99), throwsRangeError);
    });
  });

  group('TandaCardItem - Widget Tests', () {
    const tandaAlDia = TandaEntity(
      id: '1',
      nombre: 'Tanda Verano 2026',
      monto: 1500.0,
      totalParticipantes: 8,
      periodo: 'quincenal',
      estado: 'ACTIVA',
      inviteCode: 'TND-VER1',
      indicadorPago: IndicadorPago.alDia,
    );

    const tandaPendiente = TandaEntity(
      id: '2',
      nombre: 'Tanda Coche',
      monto: 3000.0,
      totalParticipantes: 10,
      periodo: 'mensual',
      estado: 'PENDIENTE',
      inviteCode: 'TND-CAR2',
      indicadorPago: IndicadorPago.pendiente,
    );

    Widget buildCard(TandaEntity tanda, {String rol = 'participante'}) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<TandasProvider>.value(
            value: provider,
            child: TandaCardItem(
              tanda: tanda,
              rol: rol,
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza chip de estado de tanda, métricas y chip de pago Al Día', (tester) async {
      await tester.pumpWidget(buildCard(tandaAlDia));

      expect(find.text('Tanda Verano 2026'), findsOneWidget);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('\$1500.00'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('\$12000.00'), findsOneWidget);

      // Indicador de pago Al día
      expect(find.byKey(const Key('badge_pago_al_dia_1')), findsOneWidget);
      expect(find.text('Al día'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renderiza chip de pago Pendiente cuando corresponda', (tester) async {
      await tester.pumpWidget(buildCard(tandaPendiente));

      expect(find.text('Tanda Coche'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsOneWidget);

      // Indicador de pago Pendiente
      expect(find.byKey(const Key('badge_pago_pendiente_2')), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('rol organizador muestra botón Compartir con código', (tester) async {
      await tester.pumpWidget(buildCard(tandaAlDia, rol: 'organizador'));

      expect(find.byKey(const Key('btn_compartir_1')), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);
    });

    testWidgets('rol participante muestra botón Ver detalle', (tester) async {
      await tester.pumpWidget(buildCard(tandaAlDia, rol: 'participante'));

      expect(find.byKey(const Key('btn_detalle_1')), findsOneWidget);
      expect(find.text('Ver detalle'), findsOneWidget);
    });

    testWidgets('participante con turno ve "Pagar" y abre Registrar pago con su número y la cuota',
        (tester) async {
      RegistrarPagoArgs? recibidos;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: ChangeNotifierProvider<TandasProvider>.value(
                value: provider,
                child: TandaCardItem(
                  tanda: tandaAlDia.copyWith(idNumberUsuario: 101, numeroTurnoUsuario: 3),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/pagos/nuevo',
            builder: (_, state) {
              recibidos = state.extra as RegistrarPagoArgs;
              return const Scaffold(body: Text('PANTALLA_PAGO'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.byKey(const Key('btn_detalle_1')), findsNothing);
      await tester.tap(find.byKey(const Key('btn_pagar_1')));
      await tester.pumpAndSettle();

      expect(find.text('PANTALLA_PAGO'), findsOneWidget);
      expect(recibidos!.idNumber, 101);
      expect(recibidos!.numeroTurno, 3);
      expect(recibidos!.cuota, 1500.0);
    });

    test('TandaModel lee miNumero de GET /tandas/mias', () {
      final tanda = TandaModel.fromJson(const {
        'idTanda': 7,
        'name': 'Tanda Oficina',
        'contributionAmount': 500,
        'numParticipants': 5,
        'status': 'ACTIVA',
        'miNumero': {'idNumber': 42, 'numberValue': 2, 'roundNumber': 1},
      });

      expect(tanda.idNumberUsuario, 42);
      expect(tanda.numeroTurnoUsuario, 2);
    });
  });

  group('MisTandasListView - ListView.builder con Selector por Tarjeta Tests', () {
    Widget buildListView({String rol = 'participante'}) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<TandasProvider>.value(
            value: provider,
            child: MisTandasListView(rol: rol),
          ),
        ),
      );
    }

    testWidgets('renderiza ListView.builder y construye cada tarjeta mediante Selector', (tester) async {
      await tester.pumpWidget(buildListView());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('list_mis_tandas')), findsOneWidget);
      expect(find.byKey(const Key('selector_tanda_1')), findsOneWidget);
      expect(find.byKey(const Key('selector_tanda_2')), findsOneWidget);
      expect(find.byKey(const Key('tanda_card_1')), findsOneWidget);
      expect(find.byKey(const Key('tanda_card_2')), findsOneWidget);

      // Verificación de los indicadores de pago en la lista
      expect(find.text('Al día'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando la lista de tandas no contiene elementos', (tester) async {
      mockRepo.getMisTandasResult = const Success([]);

      await tester.pumpWidget(buildListView(rol: 'participante'));
      await tester.pumpAndSettle();

      expect(find.text('Aún no te has unido a ninguna tanda'), findsOneWidget);
      expect(find.byKey(const Key('btn_unirse_tanda_empty')), findsOneWidget);
    });

    testWidgets('muestra mensaje de error y botón Reintentar cuando falla la carga', (tester) async {
      mockRepo.getMisTandasResult = const Error(
        ServerFailure('Error en la red móvil', statusCode: 503),
      );

      await tester.pumpWidget(buildListView());
      await tester.pumpAndSettle();

      expect(find.text('No se pudieron cargar tus tandas'), findsOneWidget);
      expect(find.text('Error en la red móvil'), findsOneWidget);
      expect(find.byKey(const Key('btn_reintentar_tandas')), findsOneWidget);

      // Al presionar reintentar
      mockRepo.getMisTandasResult = const Success([]);
      await tester.tap(find.byKey(const Key('btn_reintentar_tandas')));
      await tester.pumpAndSettle();

      expect(find.text('Aún no te has unido a ninguna tanda'), findsOneWidget);
    });
  });

  group('MisTandasScreens - Pantallas Principales', () {
    testWidgets('MisTandasParticipanteScreen contiene FloatingActionButton para unirse', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TandasProvider>.value(
            value: provider,
            child: const MisTandasParticipanteScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis tandas (participante)'), findsOneWidget);
      expect(find.byKey(const Key('fab_unirse_tanda')), findsOneWidget);
    });

    testWidgets('MisTandasOrganizadorScreen contiene FloatingActionButton para crear tanda', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TandasProvider>.value(
            value: provider,
            child: const MisTandasOrganizadorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis tandas (organizador)'), findsOneWidget);
      expect(find.byKey(const Key('fab_nueva_tanda')), findsOneWidget);
    });
  });

  group('BUG-A2 - Mis tandas se recarga al volver a la pantalla', () {
    testWidgets('recarga la lista al regresar de otra pantalla', (tester) async {
      final repo = TandasRepositoryFake();
      final router = GoRouter(
        initialLocation: RouteNames.tandasOrganizador,
        routes: [
          GoRoute(
            path: RouteNames.tandasOrganizador,
            builder: (_, _) => ChangeNotifierProvider(
              create: (_) => TandasProvider(tandasRepository: repo),
              child: const Scaffold(body: MisTandasListView(rol: 'organizador')),
            ),
          ),
          GoRoute(path: RouteNames.crearTanda, builder: (_, _) => const Scaffold(body: Text('FORM'))),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(repo.llamadasMisTandas, 1);

      unawaited(router.push(RouteNames.crearTanda));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(repo.llamadasMisTandas, 2);
    });
  });
}
