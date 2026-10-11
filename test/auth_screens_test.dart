import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    testWidgets('renderiza formulario con Form, TextFormFields y botón de inicio de sesión',
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

      final emailField = find.widgetWithText(TextFormField, 'Correo electrónico');
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

      fakeRepo.loginResult =
          const Error(UnauthorizedFailure('Credenciales inválidas. Revisa tu correo y contraseña.'));

      await tester.pumpWidget(
        createTestWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'Correo electrónico');
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
      final emailField = find.widgetWithText(TextFormField, 'Correo electrónico *');
      final passField = find.widgetWithText(TextFormField, 'Contraseña *');
      final confirmField =
          find.widgetWithText(TextFormField, 'Confirmar contraseña *');

      await tester.enterText(nameField, 'Pedro');
      await tester.enterText(emailField, 'pedro@tandea.app');
      await tester.enterText(passField, 'Contraseña123');
      await tester.enterText(confirmField, 'OtraContraseñaDistinta');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Registrarse');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });
  });
}
