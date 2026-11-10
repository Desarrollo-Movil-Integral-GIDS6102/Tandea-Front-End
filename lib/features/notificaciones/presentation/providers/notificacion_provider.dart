import 'package:flutter/foundation.dart';
import 'package:tandea/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:tandea/features/notificaciones/domain/repositories/notificacion_repository.dart';

/// Bandeja de notificaciones con contador de no leídas (global para la campana del AppBar).
class NotificacionProvider extends ChangeNotifier {
  final NotificacionRepository notificacionRepository;

  NotificacionProvider({required this.notificacionRepository});

  List<NotificacionEntity> _notificaciones = const [];
  int _noLeidas = 0;
  bool _cargando = false;
  bool _cargadoUnaVez = false;
  String? _errorMessage;

  List<NotificacionEntity> get notificaciones => _notificaciones;
  int get noLeidas => _noLeidas;
  bool get cargando => _cargando;
  bool get cargadoUnaVez => _cargadoUnaVez;
  String? get errorMessage => _errorMessage;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    final result = await notificacionRepository.obtenerBandeja();
    result.when(
      success: (bandeja) {
        _notificaciones = bandeja.notificaciones;
        _noLeidas = bandeja.noLeidas;
        _cargadoUnaVez = true;
      },
      failure: (failure) => _errorMessage = failure.message,
    );
    _cargando = false;
    notifyListeners();
  }

  /// Marca la notificación como leída al instante y revierte si el backend falla.
  Future<void> marcarLeida(NotificacionEntity notificacion) async {
    if (notificacion.leida) return;
    final anteriores = _notificaciones;
    _notificaciones = [
      for (final n in _notificaciones)
        n.idNotification == notificacion.idNotification ? n.marcadaLeida() : n,
    ];
    _noLeidas = _noLeidas > 0 ? _noLeidas - 1 : 0;
    notifyListeners();

    final result = await notificacionRepository.marcarLeida(notificacion.idNotification);
    if (result.isFailure) {
      _notificaciones = anteriores;
      _noLeidas++;
      _errorMessage = result.failureOrNull?.message;
      notifyListeners();
    }
  }

  /// Al cerrar sesión, para que la siguiente cuenta no vea la bandeja anterior.
  void limpiar() {
    _notificaciones = const [];
    _noLeidas = 0;
    _cargadoUnaVez = false;
    _errorMessage = null;
    notifyListeners();
  }
}
