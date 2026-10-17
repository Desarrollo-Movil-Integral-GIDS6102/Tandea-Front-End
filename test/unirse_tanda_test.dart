import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
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
        const Success(
          TandaEntity(
            id: '1',
            nombre: 'Tanda Navideña',
            monto: 1000.0,
            totalParticipantes: 5,
            periodo: 'quincenal',
            estado: 'PENDIENTE',
            inviteCode: 'TND-7K9A',
            idTandaType: 1, // Por elección
          ),
        );
  }

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
            numeroAsignado: params.selectedNumber ?? 2,
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
        text: 'tnd-7k9a',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('TND-7K9A'));
    });
  });

  group('UnirseTandaProvider - Validación Regex 8 Caracteres y Errores', () {
    test('estado inicial está limpio', () {
      expect(provider.inviteCode, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.validationError, isNull);
      expect(provider.backendError, isNull);
      expect(provider.foundTanda, isNull);
    });

    test('validarCodigoLocal rechaza código vacío', () {
      provider.setInviteCode('');
      final isValid = provider.validarCodigoLocal();

      expect(isValid, isFalse);
      expect(provider.validationError, contains('Ingresa el código'));
    });

    test('validarCodigoLocal rechaza códigos con menos de 8 caracteres', () {
      provider.setInviteCode('TND-12');
      final isValid = provider.validarCodigoLocal();

      expect(isValid, isFalse);
      expect(provider.validationError, contains('exactamente 8 caracteres'));
    });

    test('validarCodigoLocal rechaza códigos con más de 8 caracteres', () {
      provider.setInviteCode('TND-123456');
      final isValid = provider.validarCodigoLocal();

      expect(isValid, isFalse);
      expect(provider.validationError, contains('exactamente 8 caracteres'));
    });

    test('validarCodigoLocal rechaza caracteres no alfanuméricos fuera de guión', () {
      provider.setInviteCode('TND*1234');
      final isValid = provider.validarCodigoLocal();

      expect(isValid, isFalse);
      expect(provider.validationError, contains('exactamente 8 caracteres'));
    });

    test('validarCodigoLocal acepta códigos válidos de 8 caracteres alfanuméricos con o sin guión', () {
      provider.setInviteCode('TND-7K9A');
      expect(provider.validarCodigoLocal(), isTrue);
      expect(provider.validationError, isNull);

      provider.setInviteCode('ABC12345');
      expect(provider.validarCodigoLocal(), isTrue);
      expect(provider.validationError, isNull);
    });

    test('consultarTanda NO llama al API si el regex de 8 caracteres no se cumple', () async {
      provider.setInviteCode('CORTA');
      final tanda = await provider.consultarTanda();

      expect(tanda, isNull);
      expect(mockRepo.lastQueriedCode, isNull);
      expect(provider.validationError, isNotNull);
    });

    test('consultarTanda muestra el error devuelto por el backend cuando la tanda no existe', () async {
      provider.setInviteCode('TND-0000');
      mockRepo.getTandaResult = const Error(
        ServerFailure('No se encontró ninguna tanda activa con el código TND-0000', statusCode: 404),
      );

      final tanda = await provider.consultarTanda();

      expect(tanda, isNull);
      expect(mockRepo.lastQueriedCode, equals('TND-0000'));
      expect(provider.backendError, equals('No se encontró ninguna tanda activa con el código TND-0000'));
      expect(provider.isLoading, isFalse);
    });

    test('consultarTanda exitoso detecta correctamente si es por elección (idTandaType == 1)', () async {
      provider.setInviteCode('TND-ELEC');
      mockRepo.getTandaResult = const Success(
        TandaEntity(
          id: '1',
          nombre: 'Tanda Por Elección',
          monto: 1000.0,
          totalParticipantes: 5,
          periodo: 'quincenal',
          estado: 'PENDIENTE',
          inviteCode: 'TND-ELEC',
          idTandaType: 1,
        ),
      );

      final tanda = await provider.consultarTanda();

      expect(tanda, isNotNull);
      expect(provider.isPorEleccion, isTrue);
      expect(provider.backendError, isNull);
    });

    test('consultarTanda exitoso detecta cuando es por sorteo (idTandaType == 2)', () async {
      provider.setInviteCode('TND-SORT');
      mockRepo.getTandaResult = const Success(
        TandaEntity(
          id: '2',
          nombre: 'Tanda Sorteo',
          monto: 500.0,
          totalParticipantes: 10,
          periodo: 'semanal',
          estado: 'PENDIENTE',
          inviteCode: 'TND-SORT',
          idTandaType: 2,
        ),
      );

      final tanda = await provider.consultarTanda();

      expect(tanda, isNotNull);
      expect(provider.isPorEleccion, isFalse);
    });

    test('unirse expone el error de backend si el turno seleccionado ya está ocupado', () async {
      provider.setInviteCode('TND-7K9A');
      mockRepo.joinTandaResult = const Error(
        ServerFailure('El turno número 3 ya está ocupado', statusCode: 409),
      );

      final resultado = await provider.unirse(selectedNumber: 3);

      expect(resultado, isNull);
      expect(provider.backendError, equals('El turno número 3 ya está ocupado'));
    });

    test('unirse completa exitosamente y almacena joinResult con número asignado', () async {
      provider.setInviteCode('TND-7K9A');

      final resultado = await provider.unirse(selectedNumber: 4);

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

    testWidgets('renderiza campo de texto de código, botón Continuar y banner informativo', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      expect(find.text('Ingresa el Código de Invitación'), findsOneWidget);
      expect(find.byKey(const Key('input_codigo_tanda')), findsOneWidget);
      expect(find.byKey(const Key('btn_buscar_tanda')), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('0/8'), findsOneWidget);
    });

    testWidgets('ingresar texto en minúsculas se visualiza en mayúsculas y respeta límite de 8 caracteres', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      final inputFinder = find.byKey(const Key('input_codigo_tanda'));
      await tester.enterText(inputFinder, 'abc-1234');
      await tester.pump();

      expect(find.text('ABC-1234'), findsOneWidget);
      expect(find.text('8/8'), findsOneWidget);
    });


    testWidgets('validación local muestra error si se envía código con menos de 8 caracteres sin llamar al API', (tester) async {
      await tester.pumpWidget(buildTestScreen(provider));

      await tester.enterText(find.byKey(const Key('input_codigo_tanda')), 'ABC');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_buscar_tanda')));
      await tester.pumpAndSettle();

      expect(find.text('El código debe tener exactamente 8 caracteres'), findsOneWidget);
      expect(mockRepo.lastQueriedCode, isNull);
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
      inviteCode: 'TND-7K9A',
      idTandaType: 1,
    );

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

      expect(find.text('Confirmar Turno #3 y Unirme'), findsOneWidget);

      final btn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirmar_turno')));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('si el backend responde con error de turno ocupado, se muestra en el banner de error', (tester) async {
      provider.setInviteCode('TND-7K9A');
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
      provider.setInviteCode('TND-7K9A');
      mockRepo.joinTandaResult = const Success(
        UnirseTandaResult(
          tanda: testTanda,
          numeroAsignado: 3,
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


  });
}
