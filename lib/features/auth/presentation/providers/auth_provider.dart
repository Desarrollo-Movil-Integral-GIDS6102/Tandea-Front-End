import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/entities/user_role.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';

/// Estados explícitos de autenticación solicitados para la aplicación.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Mantenido para compatibilidad con código existente que use EstadoCarga
enum EstadoCarga { inicial, cargando, exito, error }

/// Proveedor de estado para la gestión del flujo de autenticación de usuarios.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AuthSessionProvider? _sessionProvider;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _currentUser;
  String? _errorMessage;

  AuthProvider({
    required AuthRepository authRepository,
    AuthSessionProvider? sessionProvider,
  })  : _authRepository = authRepository,
        _sessionProvider = sessionProvider;

  // ===================== ESTADOS SOLICITADOS =====================

  /// Estado actual del flujo de autenticación (loading, error, authenticated, etc.)
  AuthStatus get status => _status;

  /// Indica si hay una operación en proceso (estado loading)
  bool get isLoading => _status == AuthStatus.loading;

  /// Indica si ocurrió un error en la última operación (estado error)
  bool get isError => _status == AuthStatus.error;

  /// Indica si el usuario está autenticado válidamente (estado authenticated)
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;

  /// Indica si el estado es inicial
  bool get isInitial => _status == AuthStatus.initial;

  /// Indica si el usuario no tiene sesión activa
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  /// Compatibilidad con EstadoCarga previo
  EstadoCarga get estado => switch (_status) {
        AuthStatus.initial => EstadoCarga.inicial,
        AuthStatus.loading => EstadoCarga.cargando,
        AuthStatus.authenticated => EstadoCarga.exito,
        AuthStatus.unauthenticated => EstadoCarga.inicial,
        AuthStatus.error => EstadoCarga.error,
      };

  UserEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  // ===================== ACCIONES DE AUTENTICACIÓN =====================

  /// Inicia sesión con correo y contraseña.
  /// Cambia a loading -> authenticated (éxito) o error (fallo).
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(
      email: email.trim(),
      password: password,
    );

    return result.when(
      success: (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;

        _syncSession(user);

        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      },
    );
  }

  /// Registra un nuevo usuario en la plataforma.
  /// Cambia a loading -> authenticated (éxito) o error (fallo).
  Future<bool> register({
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    int? edad,
    String? genero,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.register(
      email: email.trim(),
      password: password,
      nombre: nombre,
      apellido: apellido,
      edad: edad,
      genero: genero,
    );

    return result.when(
      success: (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;

        _syncSession(user);

        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      },
    );
  }

  /// Verifica si existe una sesión activa y obtiene el perfil del usuario.
  Future<void> checkAuthStatus() async {
    final hasToken = await _authRepository.isAuthenticated();
    if (!hasToken) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _authRepository.getCurrentUser();
    result.when(
      success: (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        _syncSession(user);
        notifyListeners();
      },
      failure: (failure) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = failure.message;
        notifyListeners();
      },
    );
  }

  /// Cierra la sesión activa y elimina credenciales seguras.
  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _sessionProvider?.clearSession();
    notifyListeners();
  }

  /// Maneja la expiración de sesión por error 401.
  void handleUnauthorized() {
    _currentUser = null;
    _errorMessage = 'Sesión expirada. Inicia sesión nuevamente.';
    _status = AuthStatus.error;
    _sessionProvider?.clearSession();
    notifyListeners();
  }

  /// Limpia el mensaje de error para reintentos del usuario en pantalla.
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Sincroniza el rol y token con el AuthSessionProvider que escucha GoRouter.
  void _syncSession(UserEntity user) {
    if (_sessionProvider != null) {
      final role = UserRole.fromString(user.rol);
      _sessionProvider.setSession(
        token: user.token ?? '',
        role: role,
      );
    }
  }
}
