import 'package:flutter/foundation.dart';
import 'package:tandea/features/tandas/domain/entities/movimiento_historial.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_historial_tanda_usecase.dart';

/// Estado del historial de la tanda con scroll infinito (AP-09).
///
/// [cargar] trae la primera página; [cargarMas] pide la siguiente con el
/// `nextCursor` mientras haya más y no se esté cargando ya otra.
class HistorialTandaProvider extends ChangeNotifier {
  static const int tamanoPagina = 20;

  final ObtenerHistorialTandaUseCase obtenerHistorialUseCase;

  HistorialTandaProvider({required this.obtenerHistorialUseCase});

  String? _idTanda;
  final List<MovimientoHistorial> _movimientos = [];
  String? _cursor;
  bool _hayMas = false;
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _cargadoUnaVez = false;
  String? _errorMessage;

  List<MovimientoHistorial> get movimientos => List.unmodifiable(_movimientos);
  bool get hayMas => _hayMas;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  String? get errorMessage => _errorMessage;

  /// Ya respondió el backend al menos una vez (para distinguir "vacío" de "cargando").
  bool get cargadoUnaVez => _cargadoUnaVez;
  bool get vacio => _cargadoUnaVez && _movimientos.isEmpty;

  Future<void> cargar(String idTanda) async {
    _idTanda = idTanda;
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    final result = await obtenerHistorialUseCase(
      HistorialParams(idTanda: idTanda, limit: tamanoPagina),
    );
    result.when(
      success: (pagina) {
        _movimientos
          ..clear()
          ..addAll(pagina.items);
        _cursor = pagina.nextCursor;
        _hayMas = pagina.hayMas;
        _cargadoUnaVez = true;
      },
      failure: (failure) => _errorMessage = failure.message,
    );
    _cargando = false;
    notifyListeners();
  }

  Future<void> recargar() async {
    final idTanda = _idTanda;
    if (idTanda != null) await cargar(idTanda);
  }

  Future<void> cargarMas() async {
    final idTanda = _idTanda;
    if (idTanda == null || !_hayMas || _cargando || _cargandoMas) return;

    _cargandoMas = true;
    _errorMessage = null;
    notifyListeners();

    final result = await obtenerHistorialUseCase(
      HistorialParams(idTanda: idTanda, cursor: _cursor, limit: tamanoPagina),
    );
    result.when(
      success: (pagina) {
        _movimientos.addAll(pagina.items);
        _cursor = pagina.nextCursor;
        _hayMas = pagina.hayMas;
      },
      // Se conserva lo ya cargado; el usuario puede reintentar desde el final de la lista
      failure: (failure) => _errorMessage = failure.message,
    );
    _cargandoMas = false;
    notifyListeners();
  }
}
