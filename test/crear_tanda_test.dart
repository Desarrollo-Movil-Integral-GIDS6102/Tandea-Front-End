import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/services/calcular_plan.dart';
import 'package:tandea/features/tandas/domain/usecases/crear_tanda_usecase.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';
import 'package:tandea/features/tandas/presentation/providers/crear_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/screens/crear_tanda_screen.dart';
import 'package:tandea/features/tandas/presentation/widgets/dias_gracia_stepper.dart';
import 'package:tandea/features/tandas/presentation/widgets/resumen_estimado_card.dart';
import 'package:tandea/injection/injection.dart';

class MockTandasRepository implements TandasRepository {
  Map<String, dynamic>? lastCreatedPayload;
  Result<TandaEntity>? createTandaResult;

  @override
  Future<Result<List<TandaEntity>>> getTandas() async {
    return const Success([]);
  }

  @override
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol}) async {
    return const Success([]);
  }


  @override
  Future<Result<TandaEntity>> getTandaById(String id) async {
    return const Success(TandaEntity(
      id: '1',
      nombre: 'Test',
      monto: 100,
      totalParticipantes: 5,
      periodo: 'quincenal',
      estado: 'activa',
    ));
  }

  @override
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> tandaData) async {
    lastCreatedPayload = tandaData;
    return createTandaResult ??
        const Success(TandaEntity(
          id: '10',
          nombre: 'Tanda Creada',
          monto: 1000.0,
          totalParticipantes: 5,
          periodo: 'quincenal',
          estado: 'PENDIENTE',
          inviteCode: 'TND-TEST123',
        ));
  }

  @override
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode) async {
    return const Success(TandaEntity(
      id: '10',
      nombre: 'Tanda Test',
      monto: 1000.0,
      totalParticipantes: 5,
      periodo: 'quincenal',
      estado: 'PENDIENTE',
      inviteCode: 'TND-TEST',
      idTandaType: 1,
    ));
  }

  @override
  Future<Result<TandaEntity>> iniciarTanda(String id) async => getTandaById(id);

  @override
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params) async {
    return const Success(UnirseTandaResult(
      tanda: TandaEntity(
        id: '10',
        nombre: 'Tanda Test',
        monto: 1000.0,
        totalParticipantes: 5,
        periodo: 'quincenal',
        estado: 'PENDIENTE',
      ),
      numeroAsignado: 1,
    ));
  }
}


void main() {
  late MockTandasRepository mockRepo;
  late CrearTandaUseCase crearTandaUseCase;
  late CrearTandaProvider provider;

  setUp(() {
    mockRepo = MockTandasRepository();
    crearTandaUseCase = CrearTandaUseCase(repository: mockRepo);
    provider = CrearTandaProvider(crearTandaUseCase: crearTandaUseCase);
  });

  group('CrearTandaProvider - Lógica y Recálculo en tiempo real', () {
    test('estado inicial tiene valores por defecto y plan estimado calculado', () {
      expect(provider.montoCuota, equals(1000.0));
      expect(provider.numParticipantes, equals(5));
      expect(provider.numRounds, equals(1));
      expect(provider.graceDays, equals(0));
      expect(provider.hasDeadNumber, isFalse);
      expect(provider.isRandomAssignment, isFalse);
      expect(provider.idTandaType, equals(1));
      expect(provider.periodicidad, equals(PeriodicidadTanda.quincenal));
      expect(provider.planEstimado, isNotNull);
      expect(provider.planEstimado!.totalNumeros, equals(5));
      expect(provider.planEstimado!.montoPorTurno, equals(5000.0));
    });

    test('recalcula plan al cambiar periodicidad, cuota y participantes', () {
      provider.setMontoCuota(2500.0);
      provider.setNumParticipantes(10);
      provider.setPeriodicidad(PeriodicidadTanda.mensual);

      expect(provider.planEstimado, isNotNull);
      expect(provider.planEstimado!.totalNumeros, equals(10));
      expect(provider.planEstimado!.montoPorTurno, equals(25000.0));
      expect(provider.planEstimado!.montoTotalPorParticipante, equals(25000.0));
      expect(provider.periodicidad, equals(PeriodicidadTanda.mensual));
    });

    test('recalcula plan al activar número muerto (+1 turno)', () {
      provider.setNumParticipantes(6);
      provider.setTieneNumeroMuerto(true);

      expect(provider.hasDeadNumber, isTrue);
      expect(provider.planEstimado!.totalNumeros, equals(7)); // 6 + 1
      expect(provider.planEstimado!.totalTurnos, equals(7));
    });

    test('incrementar y decrementar días de gracia respetando mínimo de 0', () {
      expect(provider.graceDays, equals(0));
      provider.decrementarDiasGracia();
      expect(provider.graceDays, equals(0)); // No baja de 0

      provider.incrementarDiasGracia();
      provider.incrementarDiasGracia();
      expect(provider.graceDays, equals(2));

      provider.decrementarDiasGracia();
      expect(provider.graceDays, equals(1));

      provider.setDiasGracia(5);
      expect(provider.graceDays, equals(5));
    });

    test('cambio de asignación sorteo actualiza idTandaType (1 -> 2)', () {
      expect(provider.isRandomAssignment, isFalse);
      expect(provider.idTandaType, equals(1));

      provider.setAsignacionAleatoria(true);
      expect(provider.isRandomAssignment, isTrue);
      expect(provider.idTandaType, equals(2));
    });

    test('crearTanda valida nombre mínimo de 3 caracteres', () async {
      provider.setNombre('ab');
      final res = await provider.crearTanda();

      expect(res, isFalse);
      expect(provider.errorMessage, contains('al menos 3 caracteres'));
    });

    test('crearTanda exitoso envía los parámetros exactos a POST /tandas', () async {
      provider.setNombre('Tanda Amigos 2026');
      provider.setDescripcion('Ahorro para vacaciones');
      provider.setMontoCuota(1500.0);
      provider.setNumParticipantes(6);
      provider.setNumRounds(1);
      provider.setDiasGracia(3);
      provider.setTieneNumeroMuerto(true);
      provider.setAsignacionAleatoria(true);

      final ok = await provider.crearTanda();

      expect(ok, isTrue);
      expect(provider.createdTanda, isNotNull);
      expect(provider.createdTanda!.inviteCode, equals('TND-TEST123'));
      expect(mockRepo.lastCreatedPayload, isNotNull);
      expect(mockRepo.lastCreatedPayload!['name'], equals('Tanda Amigos 2026'));
      expect(mockRepo.lastCreatedPayload!['description'], equals('Ahorro para vacaciones'));
      expect(mockRepo.lastCreatedPayload!['contributionAmount'], equals(1500.0));
      expect(mockRepo.lastCreatedPayload!['numParticipants'], equals(6));
      expect(mockRepo.lastCreatedPayload!['numRounds'], equals(1));
      expect(mockRepo.lastCreatedPayload!['graceDays'], equals(3));
      expect(mockRepo.lastCreatedPayload!['hasDeadNumber'], isTrue);
      expect(mockRepo.lastCreatedPayload!['idTandaType'], equals(2)); // Sorteo
    });
    test('crearTanda rechaza participantes menores a 3 con mensaje exacto (QA-03)', () async {
      provider.setNombre('Tanda Familia');
      provider.setMontoCuota(1000.0);

      // Caso 0 participantes
      provider.setNumParticipantes(0);
      var ok = await provider.crearTanda();
      expect(ok, isFalse);
      expect(provider.errorMessage, equals('Una tanda requiere al menos 3 participantes'));
      expect(mockRepo.lastCreatedPayload, isNull);

      // Caso 2 participantes
      provider.setNumParticipantes(2);
      ok = await provider.crearTanda();
      expect(ok, isFalse);
      expect(provider.errorMessage, equals('Una tanda requiere al menos 3 participantes'));
      expect(mockRepo.lastCreatedPayload, isNull);

      // Caso 3 participantes (válido)
      provider.setNumParticipantes(3);
      ok = await provider.crearTanda();
      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(mockRepo.lastCreatedPayload, isNotNull);
      expect(mockRepo.lastCreatedPayload!['numParticipants'], equals(3));
    });

  });

  group('CrearTandaScreen - Widget Tests', () {
    setUp(() {
      if (sl.isRegistered<CrearTandaProvider>()) {
        sl.unregister<CrearTandaProvider>();
      }
      sl.registerFactory<CrearTandaProvider>(() => provider);
    });

    testWidgets('renderiza formulario completo con SegmentedButton, Switches, Stepper y Resumen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CrearTandaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica presencia del Resumen Estimado
      expect(find.byType(ResumenEstimadoCard), findsOneWidget);
      expect(find.text('Resumen estimado'), findsOneWidget);
      expect(find.text('En tiempo real'), findsOneWidget);

      // Verifica campos de texto
      expect(find.text('Nombre de la tanda *'), findsOneWidget);
      expect(find.text('Monto de cuota por participante *'), findsOneWidget);
      expect(find.text('Participantes *'), findsOneWidget);
      expect(find.text('Rondas/Vueltas *'), findsOneWidget);

      // Verifica SegmentedButton para periodicidad
      expect(find.byType(SegmentedButton<PeriodicidadTanda>), findsOneWidget);
      expect(find.text('Diaria'), findsOneWidget);
      expect(find.text('Semanal'), findsOneWidget);
      expect(find.descendant(of: find.byType(SegmentedButton<PeriodicidadTanda>), matching: find.text('Quincenal')), findsOneWidget);
      expect(find.text('Mensual'), findsOneWidget);

      // Verifica Stepper de días de gracia
      expect(find.byType(DiasGraciaStepper), findsOneWidget);
      expect(find.text('Días de gracia para pago'), findsOneWidget);

      // Verifica Switches para Asignación y Número Muerto
      expect(find.text('Asignación por sorteo'), findsOneWidget);
      expect(find.text('Número muerto de respaldo'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(2));

      // Verifica Botón de acción
      expect(find.text('Crear tanda'), findsOneWidget);
    });

    testWidgets('modificar cuota o participantes recalcula en tiempo real el resumen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CrearTandaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Cuota inicial: 1000 * 5 = $5,000.00
      expect(find.text(r'$5,000.00'), findsWidgets);

      // Modificar participantes a 10
      final participantesField = find.widgetWithText(TextFormField, 'Participantes *');
      await tester.enterText(participantesField, '10');
      await tester.pumpAndSettle();

      // Nuevo cálculo: 1000 * 10 = $10,000.00
      expect(find.text(r'$10,000.00'), findsWidgets);
    });

    testWidgets('interactuar con SegmentedButton actualiza periodicidad', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CrearTandaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mensual'));
      await tester.tap(find.text('Mensual'));
      await tester.pumpAndSettle();

      expect(provider.periodicidad, equals(PeriodicidadTanda.mensual));
    });

    testWidgets('interactuar con Stepper de días de gracia incrementa el valor', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CrearTandaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);

      final addBtn = find.byTooltip('Aumentar días');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(provider.graceDays, equals(1));
    });
    testWidgets('QA-03: muestra error exacto con menos de 3 participantes, lo limpia con 3 y bloquea envío inválido', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CrearTandaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      const errorMsg = 'Una tanda requiere al menos 3 participantes';
      final participantesField = find.widgetWithText(TextFormField, 'Participantes *');

      // 1. Ingresar 2 participantes -> Muestra el mensaje exacto
      await tester.enterText(participantesField, '2');
      await tester.pumpAndSettle();
      expect(find.text(errorMsg), findsOneWidget);

      // 2. Ingresar 0 participantes -> Muestra el mensaje exacto
      await tester.enterText(participantesField, '0');
      await tester.pumpAndSettle();
      expect(find.text(errorMsg), findsOneWidget);

      // 3. Dejar el campo vacío -> Muestra el mensaje exacto
      await tester.enterText(participantesField, '');
      await tester.pumpAndSettle();
      expect(find.text(errorMsg), findsOneWidget);

      // 4. Intentar enviar con campo inválido (2 participantes) -> bloquea creación
      await tester.enterText(participantesField, '2');
      await tester.pumpAndSettle();
      expect(find.text(errorMsg), findsOneWidget);

      final submitBtn = find.widgetWithText(PrimaryButton, 'Crear tanda');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // No se envía al backend ni se abre diálogo de éxito
      expect(mockRepo.lastCreatedPayload, isNull);
      expect(find.text('¡Tanda creada exitosamente!'), findsNothing);
      expect(find.text(errorMsg), findsOneWidget);

      // 5. Corregir a 3 participantes -> Se limpia el mensaje
      await tester.ensureVisible(participantesField);
      await tester.enterText(participantesField, '3');
      await tester.pumpAndSettle();
      expect(find.text(errorMsg), findsNothing);

      // 6. Completar nombre y enviar con 3 participantes -> Permite continuar con el flujo normal
      final nombreField = find.widgetWithText(TextFormField, 'Nombre de la tanda *');
      await tester.enterText(nombreField, 'Tanda de Prueba 3P');
      await tester.pumpAndSettle();

      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastCreatedPayload, isNotNull);
      expect(mockRepo.lastCreatedPayload!['numParticipants'], equals(3));
      expect(find.text('¡Tanda creada exitosamente!'), findsOneWidget);
    });

  });

  group('BUG-A1 - Navegación tras crear la tanda', () {
    testWidgets('al crear va a Mis tandas (organizador) y "atrás" no regresa al formulario', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: RouteNames.tandasOrganizador,
        routes: [
          GoRoute(
            path: RouteNames.tandasOrganizador,
            builder: (_, __) => const Scaffold(body: Text('MIS TANDAS ORG')),
          ),
          GoRoute(path: RouteNames.crearTanda, builder: (_, __) => const CrearTandaScreen()),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push(RouteNames.crearTanda);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre de la tanda *'), 'Tanda A1');
      final submitBtn = find.widgetWithText(PrimaryButton, 'Crear tanda');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_ir_mis_tandas')));
      await tester.pumpAndSettle();

      expect(find.text('MIS TANDAS ORG'), findsOneWidget);
      expect(find.byType(CrearTandaScreen), findsNothing);
      expect(router.canPop(), isFalse);
    });
  });
}
