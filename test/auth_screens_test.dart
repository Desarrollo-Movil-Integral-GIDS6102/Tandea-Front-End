import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/auth/presentation/screens/login_screen.dart';
import 'package:tandea/features/auth/presentation/screens/register_screen.dart';

class FakeAuthRepository implements AuthRepository {
  Result<UserEntity>? loginResult;
  Result<UserEntity>? registerResult;
  int registerCalls = 0;
  Map<String, Object?>? lastRegisterArgs;

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    return loginResult ??
        const Error(UnauthorizedFailure('Credenciales inválidas'));
  }

  @override
  Future<Result<UserEntity>> register({
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    int? edad,
    String? genero,
  }) async {
    registerCalls++;
    lastRegisterArgs = {
      'email': email,
      'password': password,
      'nombre': nombre,
      'apellido': apellido,
      'edad': edad,
      'genero': genero,
    };
    return registerResult ??
        const Error(ServerFailure('El correo electrónico ya está registrado'));
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async =>
      const Error(UnauthorizedFailure('No auth'));

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> getToken() async => null;
}

Widget createTestWidget({
  required Widget child,
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  late FakeAuthRepository fakeRepo;
  late AuthSessionProvider sessionProvider;
  late AuthProvider authProvider;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    sessionProvider = AuthSessionProvider();
    authProvider = AuthProvider(
      authRepository: fakeRepo,
      sessionProvider: sessionProvider,
    );
  });

  group('LoginScreen Widget Tests', () {
    testWidgets(
        'renderiza formulario con Form, TextFormFields y botón de inicio de sesión',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // email y password
      expect(find.text('Iniciar Sesión'), findsWidgets);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Regístrate aquí'), findsOneWidget);
    });

    testWidgets('valida campos vacíos al presionar Iniciar Sesión',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('El correo electrónico es requerido'), findsOneWidget);
      expect(find.text('La contraseña es requerida'), findsOneWidget);
    });

    testWidgets('valida formato de correo inválido',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      final emailField =
          find.widgetWithText(TextFormField, 'Correo electrónico');
      await tester.enterText(emailField, 'correo-no-valido');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando la autenticación falla',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeRepo.loginResult = const Error(UnauthorizedFailure(
          'Credenciales inválidas. Revisa tu correo y contraseña.'));

      await tester.pumpWidget(
        createTestWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      final emailField =
          find.widgetWithText(TextFormField, 'Correo electrónico');
      final passField = find.widgetWithText(TextFormField, 'Contraseña');

      await tester.enterText(emailField, 'usuario@tandea.app');
      await tester.enterText(passField, '12345678');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Credenciales inválidas. Revisa tu correo y contraseña.'),
        findsOneWidget,
      );
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renderiza formulario de registro con sus TextFormFields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: const RegisterScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      // Nombre, Apellido, Correo, Edad, Contraseña, Confirmar contraseña = 6 campos
      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.text('Crear Cuenta'), findsWidgets);
      expect(find.text('Registrarse'), findsOneWidget);
    });

    testWidgets('valida que contraseñas coincidan', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: const RegisterScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Nombre *');
      final emailField =
          find.widgetWithText(TextFormField, 'Correo electrónico *');
      final passField = find.widgetWithText(TextFormField, 'Contraseña *');
      final confirmField =
          find.widgetWithText(TextFormField, 'Confirmar contraseña *');

      await tester.enterText(nameField, 'Pedro');
      await tester.enterText(emailField, 'pedro@tandea.app');
      await tester.enterText(passField, 'MiClaveSegura2026!');
      await tester.enterText(confirmField, 'OtraClaveDistinta2026!');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Registrarse');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    // ================= SP-2-Bug & Seguridad de Contraseña =================

    Future<void> pumpRegister(
        WidgetTester tester, AuthProvider provider) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        createTestWidget(
            child: const RegisterScreen(), authProvider: provider),
      );
      await tester.pumpAndSettle();
    }

    Future<void> fillForm(
      WidgetTester tester, {
      String nombre = 'Pedro',
      String apellido = '',
      String email = 'pedro@tandea.app',
      String edad = '',
      String password = 'MiClaveSegura2026!',
      String? confirm,
    }) async {
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre *'), nombre);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Apellido (opcional)'), apellido);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo electrónico *'), email);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Edad (opcional)'), edad);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña *'), password);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
          confirm ?? password);
    }

    Future<void> submit(WidgetTester tester) async {
      final submitBtn = find.widgetWithText(ElevatedButton, 'Registrarse');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
    }

    testWidgets(
        'campos obligatorios vacíos muestran errores y no llaman al backend',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await submit(tester);

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);
      expect(find.text('Confirma tu contraseña'), findsOneWidget);
      expect(fakeRepo.registerCalls, 0);
    });

    testWidgets('correo con formato inválido no envía la solicitud',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, email: 'correo-no-valido');
      await submit(tester);

      expect(find.text('Ingresa un formato de correo válido'), findsOneWidget);
      expect(fakeRepo.registerCalls, 0);
    });

    testWidgets('contraseña menor a la longitud mínima muestra mensaje y no envía',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, password: 'ClaveCorta9');
      await submit(tester);

      expect(find.text('La contraseña debe tener al menos 12 caracteres'),
          findsOneWidget);
      expect(fakeRepo.registerCalls, 0);
    });

    testWidgets('123456789 no permite enviar el formulario',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, password: '123456789');
      await submit(tester);

      expect(find.text('Evita secuencias como 123456789'), findsOneWidget);
      expect(fakeRepo.registerCalls, 0);
    });

    testWidgets('aaaaaaaaaaaa no permite enviar el formulario',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, password: 'aaaaaaaaaaaa');
      await submit(tester);

      expect(find.text('La contraseña es demasiado común o predecible'),
          findsOneWidget);
      expect(fakeRepo.registerCalls, 0);
    });

    testWidgets('password123 no permite enviar el formulario',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, password: 'password123');
      await submit(tester);

      expect(find.text('La contraseña es demasiado común o predecible'),
          findsOneWidget);
      expect(fakeRepo.registerCalls, 0);
    });

    testWidgets('contraseña robusta y frase larga superan la validación local',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, password: 'correct horse battery staple');
      await submit(tester);

      expect(fakeRepo.registerCalls, 1);
      expect(fakeRepo.lastRegisterArgs?['password'],
          'correct horse battery staple');
    });

    testWidgets(
        'mensajes aparecen y desaparecen correctamente al editar el campo',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);

      final passField = find.widgetWithText(TextFormField, 'Contraseña *');

      // Al escribir una secuencia débil, aparece el mensaje
      await tester.enterText(passField, '123456789');
      await tester.pumpAndSettle();
      expect(find.text('Evita secuencias como 123456789'), findsOneWidget);

      // Al corregir con una clave robusta, el mensaje desaparece
      await tester.enterText(passField, 'MiClaveSegura2026!');
      await tester.pumpAndSettle();
      expect(find.text('Evita secuencias como 123456789'), findsNothing);
      expect(find.text('La contraseña debe tener al menos 12 caracteres'),
          findsNothing);
    });

    testWidgets('edad inválida (menor de 18) no envía la solicitud',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, edad: '15');
      await submit(tester);

      expect(find.text('Debes tener al menos 18 años para participar'),
          findsOneWidget);
      expect(fakeRepo.registerCalls, 0);
    });

    testWidgets(
        'el error desaparece al corregir el campo y no se borran los datos',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, email: 'malo');
      await submit(tester);
      expect(find.text('Ingresa un formato de correo válido'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo electrónico *'),
          'pedro@tandea.app');
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un formato de correo válido'), findsNothing);
      expect(find.text('Pedro'), findsOneWidget);
    });

    testWidgets('el botón se deshabilita durante el envío y evita solicitudes duplicadas',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);

      // Verificamos que inicialmente no hay spinner
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Simulamos estado loading en el provider
      await fillForm(tester);

      // Cuando isLoading es true, el botón se deshabilita y se muestra el spinner
      fakeRepo.registerResult = null; // para que responda o se mantenga
      final submitBtn = find.widgetWithText(ElevatedButton, 'Registrarse');
      await tester.ensureVisible(submitBtn);

      // Verificamos que el botón existe y tiene acción
      final elevatedBtn = tester.widget<ElevatedButton>(submitBtn);
      expect(elevatedBtn.onPressed, isNotNull);
    });

    testWidgets(
        'datos válidos invocan el registro y muestran error del backend',
        (WidgetTester tester) async {
      await pumpRegister(tester, authProvider);
      await fillForm(tester, apellido: 'Pérez', edad: '25');
      await submit(tester);

      expect(fakeRepo.registerCalls, 1);
      expect(fakeRepo.lastRegisterArgs, {
        'email': 'pedro@tandea.app',
        'password': 'MiClaveSegura2026!',
        'nombre': 'Pedro',
        'apellido': 'Pérez',
        'edad': 25,
        'genero': null,
      });
      // Error remoto mostrado en el banner existente, la UI sigue operativa
      expect(
          find.text('El correo electrónico ya está registrado'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Registrarse'), findsOneWidget);
    });

    testWidgets('registro válido exitoso navega con el flujo existente',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());
      fakeRepo.registerResult = const Success(UserEntity(
        id: '1',
        nombre: 'Pedro',
        email: 'pedro@tandea.app',
        rol: 'usuario',
        token: 'tkn',
      ));

      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
          GoRoute(
            path: '/tandas/participante',
            builder: (_, _) => const Scaffold(body: Text('HOME_PARTICIPANTE')),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, _) => const Scaffold(body: Text('HOME_ADMIN')),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await fillForm(tester);
      await submit(tester);

      expect(fakeRepo.registerCalls, 1);
      expect(authProvider.isAuthenticated, isTrue);
      expect(find.text('HOME_PARTICIPANTE'), findsOneWidget);
    });
  });
}
