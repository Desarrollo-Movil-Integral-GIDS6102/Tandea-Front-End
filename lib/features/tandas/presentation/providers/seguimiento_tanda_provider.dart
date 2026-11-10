import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_seguimiento_tanda_usecase.dart';

/// Pestañas del panel de seguimiento, en el orden del `TabBar`.
enum FiltroSeguimiento {
  todos('Todos'),
  pagados('Pagados'),
  pendientes('Pendientes'),
  atrasados('Atrasados');

  final String etiqueta;
  const FiltroSeguimiento(this.etiqueta);

  bool incluye(ParticipanteSeguimiento participante) => switch (this) {
        FiltroSeguimiento.todos => true,
        FiltroSeguimiento.pagados => participante.estadoPago == EstadoPagoSeguimiento.pagado,
        FiltroSeguimiento.pendientes => participante.estadoPago == EstadoPagoSeguimiento.pendiente,
        FiltroSeguimiento.atrasados => participante.estadoPago == EstadoPagoSeguimiento.atrasado,
      };
}

/// Estado del panel de seguimiento de la tanda (quién pagó / quién no).
///
/// El filtrado por pestaña se hace aquí; cada fila se reconstruye con un `Selector`
/// sobre [participanteEn], así que cambiar de pestaña solo reconstruye la lista.
class SeguimientoTandaProvider extends ChangeNotifier {
  final ObtenerSeguimientoTandaUseCase obtenerSeguimientoUseCase;

  EstadoCarga _estado = EstadoCarga.inicial;
  String? _idTanda;
  SeguimientoTanda? _seguimiento;
  String? _errorMessage;
  FiltroSeguimiento _filtro = FiltroSeguimiento.todos;
  List<ParticipanteSeguimiento> _filtrados = const [];

  SeguimientoTandaProvider({required this.obtenerSeguimientoUseCase});

  EstadoCarga get estado => _estado;
  SeguimientoTanda? get seguimiento => _seguimiento;
  String? get errorMessage => _errorMessage;
  FiltroSeguimiento get filtro => _filtro;

  bool get isLoading => _estado == EstadoCarga.cargando;
  bool get isError => _estado == EstadoCarga.error;

  List<ParticipanteSeguimiento> get participantesFiltrados => _filtrados;
  int get cantidadFiltrados => _filtrados.length;

  ParticipanteSeguimiento participanteEn(int index) => _filtrados[index];

  int get totalParticipantes => _seguimiento?.participantes.length ?? 0;
  int get totalPagados => _seguimiento?.totalPagados ?? 0;

  /// Fracción (0..1) de pagos confirmados en la vuelta actual.
  double get progreso => _seguimiento?.progreso ?? 0;

  Future<void> cargar(String idTanda) async {
    _idTanda = idTanda;
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await obtenerSeguimientoUseCase(idTanda);
    result.when(
      success: (data) {
        _seguimiento = data;
        _aplicarFiltro();
        _estado = EstadoCarga.exito;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _estado = EstadoCarga.error;
        notifyListeners();
      },
    );
  }

  /// Vuelve a consultar la última tanda cargada (p. ej. al regresar de "Revisar pago").
  Future<void> recargar() async {
    final idTanda = _idTanda;
    if (idTanda != null) {
      await cargar(idTanda);
    }
  }

  void cambiarFiltro(FiltroSeguimiento filtro) {
    if (_filtro == filtro) {
      return;
    }
    _filtro = filtro;
    _aplicarFiltro();
    notifyListeners();
  }

  void _aplicarFiltro() {
    _filtrados = List.unmodifiable(
      _seguimiento?.participantes.where(_filtro.incluye) ?? const <ParticipanteSeguimiento>[],
    );
  }
}
