import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/repositories/perfil_repository.dart';

/// Estado de las pantallas Mi perfil y Cambiar contraseña.
class PerfilProvider extends ChangeNotifier {
  final PerfilRepository perfilRepository;

  PerfilProvider({required this.perfilRepository});

  UserEntity? _perfil;
  bool _cargando = false;
  bool _guardando = false;
  bool _enviandoCodigo = false;
  bool _codigoEnviado = false;
  bool _cambiandoPassword = false;
  String? _errorMessage;
  String? _mensaje;

  UserEntity? get perfil => _perfil;
  bool get cargando => _cargando;
  bool get guardando => _guardando;
  bool get enviandoCodigo => _enviandoCodigo;
  bool get codigoEnviado => _codigoEnviado;
  bool get cambiandoPassword => _cambiandoPassword;
  String? get errorMessage => _errorMessage;
  String? get mensaje => _mensaje;

  void limpiarMensajes() {
    _errorMessage = null;
    _mensaje = null;
    notifyListeners();
  }

  Future<void> cargar() async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    final result = await perfilRepository.obtenerPerfil();
    result.when(
      success: (p) => _perfil = p,
      failure: (f) => _errorMessage = f.message,
    );
    _cargando = false;
    notifyListeners();
  }

  Future<bool> guardar({
    required String nombre,
    required String apellido,
    int? edad,
    String? genero,
  }) async {
    _guardando = true;
    _errorMessage = null;
    _mensaje = null;
    notifyListeners();

    final result = await perfilRepository.actualizarPerfil(
      nombre: nombre,
      apellido: apellido,
      edad: edad,
      genero: genero,
    );
    final ok = result.when(
      success: (p) {
        _perfil = p;
        _mensaje = 'Perfil actualizado';
        return true;
      },
      failure: (f) {
        _errorMessage = f.message;
        return false;
      },
    );
    _guardando = false;
    notifyListeners();
    return ok;
  }

  Future<bool> enviarCodigo() async {
    if (_enviandoCodigo) return false;
    _enviandoCodigo = true;
    _errorMessage = null;
    _mensaje = null;
    notifyListeners();

    final result = await perfilRepository.solicitarCodigoPassword();
    final ok = result.when(
      success: (m) {
        _codigoEnviado = true;
        _mensaje = m;
        return true;
      },
      failure: (f) {
        _errorMessage = f.message;
        return false;
      },
    );
    _enviandoCodigo = false;
    notifyListeners();
    return ok;
  }

  Future<bool> cambiarPassword({required String codigo, required String nuevaPassword}) async {
    if (_cambiandoPassword) return false;
    _cambiandoPassword = true;
    _errorMessage = null;
    _mensaje = null;
    notifyListeners();

    final result = await perfilRepository.cambiarPassword(
      codigo: codigo,
      nuevaPassword: nuevaPassword,
    );
    final ok = result.when(
      success: (m) {
        _mensaje = m;
        _codigoEnviado = false;
        return true;
      },
      failure: (f) {
        _errorMessage = f.message;
        return false;
      },
    );
    _cambiandoPassword = false;
    notifyListeners();
    return ok;
  }
}
