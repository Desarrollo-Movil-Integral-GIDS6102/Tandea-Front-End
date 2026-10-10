import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';

enum EstadoCarga { inicial, cargando, exito, error }

/// Proveedor de estado para la gestión de autenticación de usuarios.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  EstadoCarga _estado = EstadoCarga.inicial;
  UserEntity? _currentUser;
  String? _errorMessage;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  EstadoCarga get estado => _estado;
  UserEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Inicia sesión con credenciales de usuario
  Future<bool> login(String email, String password) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    return result.when(
      success: (user) {
        _currentUser = user;
        _estado = EstadoCarga.exito;
        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _estado = EstadoCarga.error;
        notifyListeners();
        return false;
      },
    );
  }

  /// Registra un nuevo usuario en la plataforma
  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.register(
      nombre: nombre,
      email: email,
      password: password,
    );

    return result.when(
      success: (user) {
        _currentUser = user;
        _estado = EstadoCarga.exito;
        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _estado = EstadoCarga.error;
        notifyListeners();
        return false;
      },
    );
  }

  /// Verifica si existe una sesión activa y obtiene el perfil del usuario
  Future<void> checkAuthStatus() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (!isAuth) {
      _currentUser = null;
      _estado = EstadoCarga.inicial;
      notifyListeners();
      return;
    }

    _estado = EstadoCarga.cargando;
    notifyListeners();

    final result = await _authRepository.getCurrentUser();
    result.when(
      success: (user) {
        _currentUser = user;
        _estado = EstadoCarga.exito;
        notifyListeners();
      },
      failure: (failure) {
        _currentUser = null;
        _errorMessage = failure.message;
        _estado = EstadoCarga.error;
        notifyListeners();
      },
    );
  }

  /// Cierra la sesión activa
  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _estado = EstadoCarga.inicial;
    notifyListeners();
  }

  /// Maneja la expiración de sesión por error 401
  void handleUnauthorized() {
    _currentUser = null;
    _errorMessage = 'Sesión expirada. Inicia sesión nuevamente.';
    _estado = EstadoCarga.error;
    notifyListeners();
  }
}
