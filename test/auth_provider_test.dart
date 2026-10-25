import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';

class MockAuthRepository implements AuthRepository {
  Result<UserEntity>? loginResult;
  Result<UserEntity>? registerResult;
  Result<UserEntity>? currentUserResult;
  bool isAuth = false;
  String? storedToken;

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
        const Error(ServerFailure('Error al registrar usuario'));
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    return currentUserResult ??
        const Error(UnauthorizedFailure('No autenticado'));
  }

  @override
  Future<Result<void>> logout() async {
    isAuth = false;
    storedToken = null;
    return const Success(null);
  }

  @override
  Future<bool> isAuthenticated() async {
    return isAuth;
  }

  @override
  Future<String?> getToken() async {
    return storedToken;
  }
}

void main() {
  late MockAuthRepository mockRepo;
  late AuthSessionProvider sessionProvider;
  late AuthProvider authProvider;

  const testUser = UserEntity(
    id: '1',
    nombre: 'Valeria',
    apellido: 'Hernández',
    email: 'valeria@tandea.app',
    rol: 'usuario',
    token: 'jwt_mock_token',
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    sessionProvider = AuthSessionProvider();
    authProvider = AuthProvider(
      authRepository: mockRepo,
      sessionProvider: sessionProvider,
    );
  });

  group('AuthProvider Estados y Lógica', () {
    test('Estado inicial es initial, no loading, no authenticated, no error', () {
      expect(authProvider.status, AuthStatus.initial);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isError, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.errorMessage, isNull);
    });

    test('login exitoso cambia estado a loading y luego authenticated', () async {
      mockRepo.loginResult = const Success(testUser);

      final future = authProvider.login('valeria@tandea.app', 'Secret123!');

      // Durante la ejecución o al finalizar
      final result = await future;

      expect(result, isTrue);
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.currentUser, testUser);
      expect(authProvider.errorMessage, isNull);
      expect(sessionProvider.isAuthenticated, isTrue);
      expect(sessionProvider.token, 'jwt_mock_token');
    });

    test('login fallido cambia estado a error y guarda errorMessage', () async {
      mockRepo.loginResult =
          const Error(UnauthorizedFailure('Credenciales inválidas'));

      final result = await authProvider.login('invalido@tandea.app', 'wrongpass');

      expect(result, isFalse);
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.isError, isTrue);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, 'Credenciales inválidas');
      expect(authProvider.currentUser, isNull);
    });

    test('register exitoso cambia estado a authenticated', () async {
      mockRepo.registerResult = const Success(testUser);

      final result = await authProvider.register(
        email: 'valeria@tandea.app',
        password: 'Password123!',
        nombre: 'Valeria',
        apellido: 'Hernández',
      );

      expect(result, isTrue);
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser, testUser);
      expect(sessionProvider.isAuthenticated, isTrue);
    });

    test('register con correo duplicado (409) muestra el mensaje amigable', () async {
      mockRepo.registerResult =
          const Error(ServerFailure('El correo electrónico ya está registrado', statusCode: 409));

      final result = await authProvider.register(
        email: 'existente@tandea.app',
        password: 'Password123!',
        nombre: 'Valeria',
      );

      expect(result, isFalse);
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.isError, isTrue);
      expect(
        authProvider.errorMessage,
        'El correo electrónico ingresado ya está registrado. Intenta iniciar sesión.',
      );
    });

    test('register con 422 guarda los errores por campo y se limpian al corregir', () async {
      mockRepo.registerResult = const Error(ServerFailure(
        'El apellido es requerido',
        statusCode: 422,
        fieldErrors: {'lastName': 'El apellido es requerido'},
      ));

      await authProvider.register(email: 'v@tandea.app', password: 'Tnd#9vKq', nombre: 'Valeria');

      expect(authProvider.errorMessage, 'Revisa los campos marcados en rojo.');
      expect(authProvider.fieldErrors, {'lastName': 'El apellido es requerido'});

      authProvider.limpiarErrorCampo('lastName');
      expect(authProvider.fieldErrors, isEmpty);
    });

    test('logout limpia currentUser y establece unauthenticated', () async {
      mockRepo.loginResult = const Success(testUser);
      await authProvider.login('valeria@tandea.app', 'Secret123!');
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();

      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(sessionProvider.isAuthenticated, isFalse);
    });

    test('clearError limpia el errorMessage', () async {
      mockRepo.loginResult = const Error(ServerFailure('Error temporal'));
      await authProvider.login('test@tandea.app', '12345678');

      expect(authProvider.errorMessage, isNotNull);
      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });

  });
}
