import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Proveedor de estado para la gestión y listado de tandas del usuario.
///
/// Soporta consulta por rol (participante / organizador), optimización de reconstrucción
/// mediante `Selector` por tarjeta, y manejo de estado de pago con indicador "Al día" / "Pendiente".
class TandasProvider extends ChangeNotifier {
  final TandasRepository tandasRepository;

  EstadoCarga _estado = EstadoCarga.inicial;
  List<TandaEntity> _tandas = const [];
  TandaEntity? _selectedTanda;
  String? _errorMessage;
  String _rolSeleccionado = 'participante'; // 'participante' | 'organizador'

  TandasProvider({required this.tandasRepository});

  // --- Getters ---
  EstadoCarga get estado => _estado;
  List<TandaEntity> get tandas => _tandas;
  TandaEntity? get selectedTanda => _selectedTanda;
  String? get errorMessage => _errorMessage;
  String get rolSeleccionado => _rolSeleccionado;

  bool get isLoading => _estado == EstadoCarga.cargando;
  bool get isError => _estado == EstadoCarga.error;
  bool get isExito => _estado == EstadoCarga.exito;
  int get cantidadTandas => _tandas.length;

  /// Obtiene la tanda en una posición específica.
  /// Usado por [Selector] en cada tarjeta del `ListView.builder` para evitar reconstrucciones innecesarias.
  TandaEntity obtenerTandaEn(int index) {
    if (index >= 0 && index < _tandas.length) {
      return _tandas[index];
    }
    throw RangeError.index(index, _tandas, 'index');
  }

  /// Consulta las tandas del usuario según su rol: `GET /tandas/mias?rol=participante|organizador`.
  Future<void> fetchMisTandas({String? rol}) async {
    if (rol != null && rol.isNotEmpty) {
      _rolSeleccionado = rol;
    }

    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await tandasRepository.getMisTandas(rol: _rolSeleccionado);
    result.when(
      success: (data) {
        _tandas = data;
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

  /// Alterna el rol entre 'participante' y 'organizador' y refresca la lista.
  Future<void> cambiarRol(String nuevoRol) async {
    if (_rolSeleccionado != nuevoRol) {
      _rolSeleccionado = nuevoRol;
      await fetchMisTandas(rol: nuevoRol);
    }
  }

  /// Alterna interactivamente el indicador de pago mock (Al día / Pendiente) para una tanda.
  /// Facilita pruebas y demostración de estado de cobro/pago mientras no exista el endpoint de pagos.
  void toggleIndicadorPagoMock(String idTanda) {
    final index = _tandas.indexWhere((t) => t.id == idTanda);
    if (index != -1) {
      final actual = _tandas[index];
      final nuevoEstado = actual.indicadorPago.esAlDia
          ? IndicadorPago.pendiente
          : IndicadorPago.alDia;

      final updatedList = List<TandaEntity>.from(_tandas);
      updatedList[index] = actual.copyWith(indicadorPago: nuevoEstado);
      _tandas = updatedList;
      notifyListeners();
    }
  }

  /// Consulta general de tandas (compatibilidad previa).
  Future<void> fetchTandas() async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await tandasRepository.getTandas();
    result.when(
      success: (data) {
        _tandas = data;
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

  /// Consulta el detalle de una tanda por ID.
  Future<void> fetchTandaById(String id) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await tandasRepository.getTandaById(id);
    result.when(
      success: (data) {
        _selectedTanda = data;
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
}
