import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/core/utils/uppercase_text_formatter.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_tanda_por_codigo_usecase.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';
import 'package:tandea/features/tandas/presentation/providers/unirse_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/screens/seleccionar_numero_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/unirse_tanda_screen.dart';

class MockUnirseTandasRepository implements TandasRepository {
  Result<TandaEntity>? getTandaResult;
  Result<UnirseTandaResult>? joinTandaResult;
  String? lastQueriedCode;
  JoinTandaParams? lastJoinParams;

  @override
  Future<Result<List<TandaEntity>>> getTandas() async => const Success([]);

  @override
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol}) async =>
      const Success([]);

  @override
  Future<Result<TandaEntity>> getTandaById(String id) async =>
      const Success(TandaEntity(
        id: '1',
        nombre: 'Mock',
        monto: 100,
        totalParticipantes: 5,
        periodo: 'quincenal',
        estado: 'activa',
      ));

  @override
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> data) async =>
      const Success(TandaEntity(
        id: '1',
        nombre: 'Mock',
        monto: 100,
        totalParticipantes: 5,
        periodo: 'quincenal',
        estado: 'activa',
      ));

  @override
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode) async {
    lastQueriedCode = inviteCode;
    return getTandaResult ??
        Success(
          TandaEntity(
            id: '1',
            nombre: 'Tanda Navideña',
            monto: 1000.0,
            totalParticipantes: 5,
            periodo: 'quincenal',
            estado: 'PENDIENTE',
            inviteCode: inviteCode,
            idTandaType: 1, // Por elección
          ),
        );
  }

  @override
  Future<Result<TandaEntity>> iniciarTanda(String id) async => getTandaById(id);

  @override
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params) async {
    lastJoinParams = params;
    return joinTandaResult ??
        Success(
          UnirseTandaResult(
            tanda: const TandaEntity(
              id: '1',
              nombre: 'Tanda Navideña',
              monto: 1000.0,
              totalParticipantes: 5,
              periodo: 'quincenal',
              estado: 'PENDIENTE',
            ),
            numeroAsignado: params.selectedNumbers.isNotEmpty ? params.selectedNumbers.first : 2,
            numerosAsignados: params.selectedNumbers,
            mensaje: 'Te has unido exitosamente a la tanda',
          ),
        );
  }
}

void main() {
  late MockUnirseTandasRepository mockRepo;
  late ObtenerTandaPorCodigoUseCase obtenerTandaUseCase;
  late UnirseTandaUseCase unirseTandaUseCase;
  late UnirseTandaProvider provider;

  setUp(() {
    mockRepo = MockUnirseTandasRepository();
    obtenerTandaUseCase = ObtenerTandaPorCodigoUseCase(repository: mockRepo);
    unirseTandaUseCase = UnirseTandaUseCase(repository: mockRepo);
    provider = UnirseTandaProvider(
      obtenerTandaPorCodigoUseCase: obtenerTandaUseCase,
      unirseTandaUseCase: unirseTandaUseCase,
    );
  });

  group('UpperCaseTextFormatter Tests', () {
    test('convierte texto en minúsculas a mayúsculas automáticamente', () {
      final formatter = UpperCaseTextFormatter();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'tnd-7k9a2b',
        selection: TextSelection.collapsed(offset: 10),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('TND-7K9A2B'));
    });
  });

  group('UnirseTandaProvider - Validación y Flujo de Invitación', () {
    test('estado inicial está limpio', () {
      expect(provider.inviteCode, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.validationError, isNull);
      expect(provider.backendError, isNull);
      expect(provider.foundTanda, isNull);
    });

    test('validarCodigoLocal rechaza cadena vacía', () {
      provider.setInviteCode('');
      final isValid = provider.validarCodigoLocal();

      expect(isValid, isFalse);
      expect(provider.validationError, contains('Ingresa el código'));
    });

    test('validarCodigoLocal rechaza códigos con 7 caracteres (menos de 8)', () {
      provider.setInviteCode('TND-123'); // 7 caracteres
      final isValid = provider.validarCodigoLocal();

      expect(isValid, isFalse);
      expect(provider.validationError, contains('entre 8 y 10 caracteres'));
    });

    test('validarCodigoLocal acepta códigos válidos de 8, 9 y 10 caracteres', () {
      // 8 caracteres
      provider.setInviteCode('TND-7K9A');
      expect(provider.validarCodigoLocal(), isTrue);
      expect(provider.validationError, isNull);

      provider.setInviteCode('ABC12345');
      expect(provider.validarCodigoLocal(), isTrue);
      expect(provider.validationError, isNull);

      // 9 caracteres
      provider.setInviteCode('TND-7K9A2');
      expect(provider.validarCodigoLocal(), isTrue);
      expect(provider.validationError, isNull);

      // 10 caracteres (formato estándar AP-02: TND- + 6 alfanuméricos)
      provider.setInviteCode('TND-7K9A2B');
      expect(provider.validarCodigoLocal(), isTrue);
      expect(provider.validationError, isNull);
    });

    test('validarCodigoLocal acepta explícitamente TND-7K9A2B', () {
      provider.setInviteCode('TND-7K9A2B');
      expect(provider.validarCodigoLocal(), isTrue);
      expect(provider.validationError, isNull);
    });

    test('validarCodigoLocal rechaza códigos con 11 caracteres (más de 10)', () {
      provider.setInviteCode('TND-7K9A2B1'); // 11 caracteres
      final isValid = provider.validarCodigoLocal();

      expect(isValid, isFalse);
      expect(provider.validationError, contains('entre 8 y 10 caracteres'));
    });

    test('validarCodigoLocal rechaza caracteres especiales no permitidos (@, espacios, símbolos)', () {
      // Arroba
      provider.setInviteCode('TND@7K9A2B');
      expect(provider.validarCodigoLocal(), isFalse);
      expect(provider.validationError, contains('entre 8 y 10 caracteres'));

      // Espacio interno
      provider.setInviteCode('TND 7K9A2B');
      expect(provider.validarCodigoLocal(), isFalse);
      expect(provider.validationError, contains('entre 8 y 10 caracteres'));

      // Carácter asterisco
      provider.setInviteCode('TND*123456');
      expect(provider.validarCodigoLocal(), isFalse);
      expect(provider.validationError, contains('entre 8 y 10 caracteres'));
    });

    test('regexCodigo exige mayúsculas; minúsculas sin formatear no hacen match', () {
      expect(UnirseTandaProvider.regexCodigo.hasMatch('tnd-7k9a2b'), isFalse);
      expect(UnirseTandaProvider.regexCodigo.hasMatch('TND-7K9A2B'), isTrue);
      expect(UnirseTandaProvider.regexCodigo.hasMatch('abc12345'), isFalse);
      expect(UnirseTandaProvider.regexCodigo.hasMatch('ABC12345'), isTrue);
    });

    test('normalización aplica trim y toUpperCase en setInviteCode', () {
      provider.setInviteCode('  tnd-7k9a2b  ');
      expect(provider.inviteCode, equals('TND-7K9A2B'));
      expect(provider.validarCodigoLocal(), isTrue);
    });

    test('consultarTanda NO llama al API si el código tiene menos de 8 o más de 10 caracteres', () async {
      provider.setInviteCode('CORTO');
      final tandaCorta = await provider.consultarTanda();
      expect(tandaCorta, isNull);
      expect(mockRepo.lastQueriedCode, isNull);
      expect(provider.validationError, isNotNull);

      provider.setInviteCode('ESTOESTOESMUYLARGO11');
      final tandaLarga = await provider.consultarTanda();
      expect(tandaLarga, isNull);
      expect(mockRepo.lastQueriedCode, isNull);
      expect(provider.validationError, isNotNull);
    });

    test('consultarTanda exitoso con TND-7K9A2B consulta el repositorio con código limpio', () async {
      provider.setInviteCode('  TND-7K9A2B  ');
      final tanda = await provider.consultarTanda();

      expect(tanda, isNotNull);
      expect(mockRepo.lastQueriedCode, equals('TND-7K9A2B'));
      expect(provider.foundTanda, isNotNull);
      expect(provider.backendError, isNull);
    });

    test('consultarTanda muestra el error devuelto por el backend cuando la tanda no existe', () async {
      provider.setInviteCode('TND-000000');
      mockRepo.getTandaResult = const Error(
        ServerFailure('No se encontró ninguna tanda activa con el código TND-000000', statusCode: 404),
      );

      final tanda = await provider.consultarTanda();

      expect(tanda, isNull);
      expect(mockRepo.lastQueriedCode, equals('TND-000000'));
      expect(provider.backendError, equals('No se encontró ninguna tanda activa con el código TND-000000'));
      expect(provider.isLoading, isFalse);
    });

    test('consultarTanda deja continuar si la tanda está pendiente y tiene números libres', () async {
      provider.setInviteCode('TND-ELEC10');
      mockRepo.getTandaResult = const Success(
        TandaEntity(
          id: '1',
          nombre: 'Tanda Abierta',
          monto: 1000.0,
          totalParticipantes: 5,
          periodo: 'quincenal',
          estado: 'PENDIENTE',
          inviteCode: 'TND-ELEC10',
          numerosDisponibles: [2, 4],
        ),
      );

      final tanda = await provider.consultarTanda();

      expect(tanda, isNotNull);
      expect(provider.backendError, isNull);
    });

    test('BUG-P5: deja unirse a una tanda ACTIVA si quedan números libres', () async {
      provider.setInviteCode('TND-7YZZCP');
      mockRepo.getTandaResult = const Success(
        TandaEntity(
          id: '2',
          nombre: 'Tanda Prueba',
          monto: 100.0,
          totalParticipantes: 4,
          periodo: 'quincenal',
          estado: 'ACTIVA',
          inviteCode: 'TND-7YZZCP',
          numerosDisponibles: [4],
        ),
      );

      expect(await provider.consultarTanda(), isNotNull);
      expect(provider.backendError, isNull);
    });

    test('BUG-P5: una tanda finalizada se rechaza con su propia causa', () async {
      provider.setInviteCode('TND-SORT10');
      mockRepo.getTandaResult = const Success(
        TandaEntity(
          id: '2',
          nombre: 'Tanda Cerrada',
          monto: 500.0,
          totalParticipantes: 10,
          periodo: 'semanal',
          estado: 'FINALIZADA',
          inviteCode: 'TND-SORT10',
          numerosDisponibles: [],
        ),
      );

      expect(await provider.consultarTanda(), isNull);
      expect(
        provider.backendError,
        'La tanda "Tanda Cerrada" está finalizada y ya no acepta participantes.',
      );
    });

    test('consultarTanda no deja intentar unirse si ya no quedan números libres', () async {
      provider.setInviteCode('TND-LLENA1');
      mockRepo.getTandaResult = const Success(
        TandaEntity(
          id: '3',
          nombre: 'Tanda Llena',
          monto: 500.0,
          totalParticipantes: 3,
          periodo: 'semanal',
          estado: 'PENDIENTE',
          inviteCode: 'TND-LLENA1',
          numerosDisponibles: [],
        ),
      );

      expect(await provider.consultarTanda(), isNull);
      expect(provider.backendError, 'La tanda "Tanda Llena" ya no tiene números disponibles.');
    });

    test('unirse expone el error de backend si el turno seleccionado ya está ocupado', () async {
      provider.setInviteCode('TND-7K9A2B');
      mockRepo.joinTandaResult = const Error(
        ServerFailure('El turno número 3 ya está ocupado', statusCode: 409),
      );

      final resultado = await provider.unirse(selectedNumbers: [3]);

      expect(resultado, isNull);
      expect(provider.backendError, equals('El turno número 3 ya está ocupado'));
    });

    test('unirse completa exitosamente y almacena joinResult con número asignado', () async {
      provider.setInviteCode('TND-7K9A2B');

      final resultado = await provider.unirse(selectedNumbers: [4]);

      expect(resultado, isNotNull);
      expect(resultado!.numeroAsignado, equals(4));
      expect(provider.joinResult, equals(resultado));
      expect(provider.backendError, isNull);
    });
  });

  group('UnirseTandaScreen - Widget Tests', () {
    Widget buildTestScreen(UnirseTandaProvider p) {
      return MaterialApp(
        home: ChangeNotifierProvider<UnirseTandaProvider>.value(
          value: p,
          child: const UnirseTandaScreen(),
        ),
      );
    }

    testWidgets('renderiza campo de texto, botón Continuar, etiqueta nueva y contador inicial 0/10', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      expect(find.text('Ingresa el Código de Invitación'), findsOneWidget);
      expect(find.text('Código de invitación'), findsOneWidget);
      expect(find.text('Código de 8 caracteres'), findsNothing);
      expect(find.byKey(const Key('input_codigo_tanda')), findsOneWidget);
      expect(find.byKey(const Key('btn_buscar_tanda')), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);

      final textField = tester.widget<TextField>(find.descendant(
        of: find.byKey(const Key('input_codigo_tanda')),
        matching: find.byType(TextField),
      ));
      expect(textField.decoration?.hintText, equals('TND-7K9A2B'));
    });

    testWidgets('ingresar texto en minúsculas se visualiza en mayúsculas', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      final inputFinder = find.byKey(const Key('input_codigo_tanda'));
      await tester.enterText(inputFinder, 'abc-123456');
      await tester.pump();

      expect(find.text('ABC-123456'), findsOneWidget);
      expect(find.text('10/10'), findsOneWidget);
    });

    testWidgets('entrada máxima de 10 caracteres: el carácter número 11 no se incorpora', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      final inputFinder = find.byKey(const Key('input_codigo_tanda'));
      await tester.enterText(inputFinder, 'TND-7K9A2B1');
      await tester.pump();

      final editableFinder = find.descendant(
        of: find.byKey(const Key('input_codigo_tanda')),
        matching: find.byType(EditableText),
      );
      final editable = tester.widget<EditableText>(editableFinder);
      expect(editable.controller.text, equals('TND-7K9A2B'));
      expect(editable.controller.text.length, equals(10));
      expect(find.text('10/10'), findsOneWidget);
    });

    testWidgets('pegar 12 caracteres deja un máximo de 10 caracteres', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      final inputFinder = find.byKey(const Key('input_codigo_tanda'));
      await tester.enterText(inputFinder, 'TND-7K9A2B99');
      await tester.pump();

      final editableFinder = find.descendant(
        of: find.byKey(const Key('input_codigo_tanda')),
        matching: find.byType(EditableText),
      );
      final editable = tester.widget<EditableText>(editableFinder);
      expect(editable.controller.text, equals('TND-7K9A2B'));
      expect(editable.controller.text.length, equals(10));
      expect(find.text('10/10'), findsOneWidget);
    });

    testWidgets('el contador llega a 10/10 cuando el campo tiene 10 caracteres', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      await tester.enterText(find.byKey(const Key('input_codigo_tanda')), 'ABC-7K9A2B');
      await tester.pump();

      expect(find.text('10/10'), findsOneWidget);
    });

    testWidgets('un código de 7 caracteres muestra error al enviar sin llamar al API', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      await tester.enterText(find.byKey(const Key('input_codigo_tanda')), 'TND-123'); // 7 caracteres
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_buscar_tanda')));
      await tester.pumpAndSettle();

      expect(find.text('El código debe tener entre 8 y 10 caracteres'), findsOneWidget);
      expect(mockRepo.lastQueriedCode, isNull);
    });

    testWidgets('TND-7K9A2B es válido y procesa la búsqueda al presionar Continuar', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ChangeNotifierProvider<UnirseTandaProvider>.value(
              value: provider,
              child: const UnirseTandaScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.seleccionarNumero,
            builder: (context, state) => const Scaffold(body: Text('Pantalla Seleccionar Numero')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.enterText(find.byKey(const Key('input_codigo_tanda')), 'TND-7K9A2B');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_buscar_tanda')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastQueriedCode, equals('TND-7K9A2B'));
      expect(find.text('Pantalla Seleccionar Numero'), findsOneWidget);
    });

    testWidgets('muestra error devuelto por el backend en el banner de error', (tester) async {
      mockRepo.getTandaResult = const Error(
        ServerFailure('No se encontró ninguna tanda activa con el código ABC12345', statusCode: 404),
      );

      await tester.pumpWidget(buildTestScreen(provider));

      await tester.enterText(find.byKey(const Key('input_codigo_tanda')), 'ABC12345');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_buscar_tanda')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_error_tanda')), findsOneWidget);
      expect(find.text('No se encontró ninguna tanda activa con el código ABC12345'), findsOneWidget);
    });
  });

  group('SeleccionarNumeroScreen - Widget Tests', () {
    const testTanda = TandaEntity(
      id: '1',
      nombre: 'Tanda Familiar 2026',
      monto: 1500.0,
      totalParticipantes: 6,
      periodo: 'quincenal',
      estado: 'PENDIENTE',
      inviteCode: 'TND-7K9A2B',
      idTandaType: 1,
    );

    // La pantalla vuelve a consultar la tanda al abrir: el backend responde la misma
    setUp(() => mockRepo.getTandaResult = const Success(testTanda));

    Widget buildTestScreen(UnirseTandaProvider p) {
      return MaterialApp(
        home: ChangeNotifierProvider<UnirseTandaProvider>.value(
          value: p,
          child: const SeleccionarNumeroScreen(tanda: testTanda),
        ),
      );
    }

    testWidgets('renderiza resumen de tanda, cuadrícula con 6 turnos y botón deshabilitado inicialmente', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      expect(find.text('Tanda Familiar 2026'), findsOneWidget);
      expect(find.text('\$1500.00'), findsOneWidget);
      expect(find.text('6 turnos'), findsOneWidget);

      for (int i = 1; i <= 6; i++) {
        expect(find.byKey(Key('btn_seleccionar_numero_$i')), findsOneWidget);
      }

      final btn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirmar_turno')));
      expect(btn.onPressed, isNull);
    });

    testWidgets('seleccionar turno #3 lo resalta y habilita el botón de confirmación', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_3')));
      await tester.pump();

      expect(find.text('Apartar número #3'), findsOneWidget);

      final btn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirmar_turno')));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('si el backend responde con error de turno ocupado, se muestra en el banner de error', (tester) async {
      provider.setInviteCode('TND-7K9A2B');
      mockRepo.joinTandaResult = const Error(
        ServerFailure('El turno número 3 ya está ocupado', statusCode: 409),
      );

      await tester.pumpWidget(buildTestScreen(provider));

      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_3')));
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('btn_confirmar_turno')));
      await tester.tap(find.byKey(const Key('btn_confirmar_turno')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_error_selector')), findsOneWidget);
      expect(find.text('El turno número 3 ya está ocupado'), findsOneWidget);
    });

    testWidgets('confirmar turno exitoso muestra el diálogo con el turno reservado', (tester) async {
      provider.setInviteCode('TND-7K9A2B');
      mockRepo.joinTandaResult = const Success(
        UnirseTandaResult(
          tanda: testTanda,
          numeroAsignado: 3,
          numerosAsignados: [3],
        ),
      );

      await tester.pumpWidget(buildTestScreen(provider));

      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_3')));
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('btn_confirmar_turno')));
      await tester.tap(find.byKey(const Key('btn_confirmar_turno')));
      await tester.pumpAndSettle();

      expect(find.text('¡Turno Reservado!'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('#3')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('btn_exito_selector_ir_tandas')), findsOneWidget);
    });

    testWidgets('BUG-P1: marca los ocupados, no deja seleccionarlos y consulta la disponibilidad al abrir', (tester) async {
      const tandaVieja = TandaEntity(
        id: '1',
        nombre: 'Tanda Familiar 2026',
        monto: 1500.0,
        totalParticipantes: 6,
        periodo: 'quincenal',
        estado: 'PENDIENTE',
        inviteCode: 'TND-7K9A2B',
        numerosDisponibles: [1, 2, 3, 4, 5, 6],
      );
      // Al abrir, el backend informa que #1, #3 y #4 ya se apartaron
      mockRepo.getTandaResult = const Success(TandaEntity(
        id: '1',
        nombre: 'Tanda Familiar 2026',
        monto: 1500.0,
        totalParticipantes: 6,
        periodo: 'quincenal',
        estado: 'PENDIENTE',
        inviteCode: 'TND-7K9A2B',
        numerosDisponibles: [2, 5, 6],
      ));
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<UnirseTandaProvider>.value(
          value: provider,
          child: const SeleccionarNumeroScreen(tanda: tandaVieja),
        ),
      ));
      await tester.pumpAndSettle();

      expect(mockRepo.lastQueriedCode, 'TND-7K9A2B');
      expect(find.text('Quedan 3 de 6 números libres. Puedes apartar más de uno.'), findsOneWidget);
      for (final n in [1, 3, 4]) {
        expect(find.byKey(Key('etiqueta_ocupado_$n')), findsOneWidget);
      }
      expect(find.byKey(const Key('etiqueta_ocupado_2')), findsNothing);

      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_1')));
      await tester.pump();
      final btn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirmar_turno')));
      expect(btn.onPressed, isNull, reason: 'un número ocupado no se puede seleccionar');
    });

    testWidgets('BUG-P2: selecciona y deselecciona varios números y aparta todos', (tester) async {
      mockRepo.getTandaResult = const Success(TandaEntity(
        id: '1',
        nombre: 'Tanda Familiar 2026',
        monto: 1500.0,
        totalParticipantes: 6,
        periodo: 'quincenal',
        estado: 'PENDIENTE',
        inviteCode: 'TND-7K9A2B',
        numerosDisponibles: [2, 5, 6],
      ));
      await tester.pumpWidget(buildTestScreen(provider));
      await tester.pumpAndSettle();

      ElevatedButton confirmar() =>
          tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirmar_turno')));
      expect(confirmar().onPressed, isNull);
      expect(find.text('Selecciona al menos un número'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_2')));
      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_2'))); // deselecciona
      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_6')));
      await tester.pump();
      expect(find.text('Apartar 2 números'), findsOneWidget);
      expect(confirmar().onPressed, isNotNull);

      await tester.ensureVisible(find.byKey(const Key('btn_confirmar_turno')));
      await tester.tap(find.byKey(const Key('btn_confirmar_turno')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastJoinParams?.selectedNumbers, equals([5, 6]));
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('#5, #6')),
        findsOneWidget,
      );
    });

    testWidgets('BUG-P3: si otro toma el número, no asigna nada, avisa y marca el ocupado', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_seleccionar_numero_3')));
      await tester.pump();

      // Mientras tanto otro participante apartó el #3
      mockRepo.joinTandaResult = const Error(ServerFailure(
        'El número #3 ya fue tomado por otro participante. Elige otro.',
        statusCode: 409,
      ));
      mockRepo.getTandaResult = const Success(TandaEntity(
        id: '1',
        nombre: 'Tanda Familiar 2026',
        monto: 1500.0,
        totalParticipantes: 6,
        periodo: 'quincenal',
        estado: 'PENDIENTE',
        inviteCode: 'TND-7K9A2B',
        numerosDisponibles: [1, 2, 4, 5, 6],
      ));

      await tester.ensureVisible(find.byKey(const Key('btn_confirmar_turno')));
      await tester.tap(find.byKey(const Key('btn_confirmar_turno')));
      await tester.pumpAndSettle();

      expect(find.text('¡Turno Reservado!'), findsNothing);
      expect(
        find.text('El número #3 ya fue tomado por otro participante. Elige otro.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('etiqueta_ocupado_3')), findsOneWidget);
      expect(find.text('Selecciona al menos un número'), findsOneWidget);
    });

    testWidgets('BUG-P6: por sorteo no hay cuadrícula; pide cantidad y consecutivos y avisa si no hubo bloque', (tester) async {
      const tandaSorteo = TandaEntity(
        id: '9',
        nombre: 'Tanda Sorteo',
        monto: 100.0,
        totalParticipantes: 6,
        periodo: 'quincenal',
        estado: 'PENDIENTE',
        inviteCode: 'TND-SORTEO',
        idTandaType: 2,
        numerosDisponibles: [1, 3, 5, 6],
      );
      mockRepo.getTandaResult = const Success(tandaSorteo);
      mockRepo.joinTandaResult = const Success(UnirseTandaResult(
        tanda: tandaSorteo,
        numeroAsignado: 1,
        numerosAsignados: [1, 3],
        consecutivos: false,
      ));
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<UnirseTandaProvider>.value(
          value: provider,
          child: const SeleccionarNumeroScreen(tanda: tandaSorteo),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('aviso_tanda_sorteo')), findsOneWidget);
      expect(find.byKey(const Key('btn_seleccionar_numero_1')), findsNothing);
      expect(find.text('Obtener números'), findsOneWidget);

      ElevatedButton obtener() =>
          tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirmar_turno')));
      await tester.tap(find.byKey(const Key('btn_menos_cantidad')));
      await tester.pump();
      expect(obtener().onPressed, isNull, reason: 'con cantidad 0 el botón queda deshabilitado');

      await tester.tap(find.byKey(const Key('btn_mas_cantidad')));
      await tester.tap(find.byKey(const Key('btn_mas_cantidad')));
      await tester.tap(find.byKey(const Key('switch_consecutivos')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('btn_confirmar_turno')));
      await tester.tap(find.byKey(const Key('btn_confirmar_turno')));
      await tester.pumpAndSettle();

      expect(mockRepo.lastJoinParams?.cantidad, 2);
      expect(mockRepo.lastJoinParams?.consecutivos, isTrue);
      expect(mockRepo.lastJoinParams?.selectedNumbers, isEmpty);
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('#1, #3')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('aviso_sorteo_no_consecutivos')), findsOneWidget);
    });
  });
}
