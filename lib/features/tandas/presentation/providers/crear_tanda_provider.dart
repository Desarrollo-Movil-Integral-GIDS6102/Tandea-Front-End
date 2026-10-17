import 'package:flutter/foundation.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/services/calcular_plan.dart';
import 'package:tandea/features/tandas/domain/usecases/crear_tanda_usecase.dart';

/// Proveedor de estado para el formulario de Creación de Tanda con cálculo en tiempo real.
class CrearTandaProvider extends ChangeNotifier {
  final CrearTandaUseCase crearTandaUseCase;

  CrearTandaProvider({required this.crearTandaUseCase}) {
    recalcularPlan();
  }

  // --- Campos del Formulario ---
  String _name = '';
  String _description = '';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  double _montoCuota = 1000.0;
  int _numParticipantes = 5;
  int _numRounds = 1;
  int _graceDays = 0;
  bool _hasDeadNumber = false;
  bool _isRandomAssignment = false; // false = Tradicional (id 1), true = Sorteo (id 2)
  PeriodicidadTanda _periodicidad = PeriodicidadTanda.quincenal;

  // --- Estado de UI y Envío ---
  bool _isLoading = false;
  String? _errorMessage;
  TandaEntity? _createdTanda;
  PlanTandaResult? _planEstimado;

  // --- Getters ---
  String get name => _name;
  String get description => _description;
  DateTime get startDate => _startDate;
  double get montoCuota => _montoCuota;
  int get numParticipantes => _numParticipantes;
  int get numRounds => _numRounds;
  int get graceDays => _graceDays;
  bool get hasDeadNumber => _hasDeadNumber;
  bool get isRandomAssignment => _isRandomAssignment;
  PeriodicidadTanda get periodicidad => _periodicidad;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TandaEntity? get createdTanda => _createdTanda;
  PlanTandaResult? get planEstimado => _planEstimado;

  /// Id del tipo de tanda en base de datos: 1 = Tradicional (manual), 2 = Sorteo (aleatoria).
  int get idTandaType => _isRandomAssignment ? 2 : 1;

  // --- Recálculo del Plan en Tiempo Real (Espejo de calcularPlan) ---
  void recalcularPlan() {
    final input = PlanTandaInput(
      periodicidad: _periodicidad,
      montoCuota: _montoCuota,
      numParticipantes: _numParticipantes,
      numVueltas: _numRounds,
      tieneNumeroMuerto: _hasDeadNumber,
      fechaInicio: _startDate,
    );

    _planEstimado = calcularPlanSafe(input);
  }

  // --- Setters con recálculo dinámico en onChanged ---

  void setNombre(String value) {
    _name = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setDescripcion(String value) {
    _description = value;
    notifyListeners();
  }

  void setFechaInicio(DateTime date) {
    _startDate = date;
    recalcularPlan();
    notifyListeners();
  }

  void setMontoCuota(double value) {
    _montoCuota = value;
    recalcularPlan();
    notifyListeners();
  }

  void setNumParticipantes(int value) {
    _numParticipantes = value;
    recalcularPlan();
    notifyListeners();
  }

  void setNumRounds(int value) {
    _numRounds = value;
    recalcularPlan();
    notifyListeners();
  }

  void setDiasGracia(int value) {
    if (value >= 0) {
      _graceDays = value;
      notifyListeners();
    }
  }

  void incrementarDiasGracia() {
    _graceDays++;
    notifyListeners();
  }

  void decrementarDiasGracia() {
    if (_graceDays > 0) {
      _graceDays--;
      notifyListeners();
    }
  }

  void setTieneNumeroMuerto(bool value) {
    _hasDeadNumber = value;
    recalcularPlan();
    notifyListeners();
  }

  void setAsignacionAleatoria(bool value) {
    _isRandomAssignment = value;
    notifyListeners();
  }

  void setPeriodicidad(PeriodicidadTanda value) {
    _periodicidad = value;
    recalcularPlan();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Envía la solicitud al endpoint `POST /tandas`.
  Future<bool> crearTanda() async {
    // Validaciones locales previas al envío
    if (_name.trim().length < 3) {
      _errorMessage = 'El nombre de la tanda debe tener al menos 3 caracteres.';
      notifyListeners();
      return false;
    }

    if (_montoCuota <= 0) {
      _errorMessage = 'El monto de la cuota debe ser mayor a 0.';
      notifyListeners();
      return false;
    }

    if (_numParticipantes < 2) {
      _errorMessage = 'Debe haber al menos 2 participantes en la tanda.';
      notifyListeners();
      return false;
    }

    if (_numParticipantes > 50) {
      _errorMessage = 'El número máximo de participantes permitido es 50.';
      notifyListeners();
      return false;
    }

    if (_numRounds < 1) {
      _errorMessage = 'Debe haber al menos 1 vuelta.';
      notifyListeners();
      return false;
    }

    if (_graceDays < 0) {
      _errorMessage = 'Los días de gracia no pueden ser negativos.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final formattedStartDate =
        '${_startDate.year.toString().padLeft(4, '0')}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';

    final params = CrearTandaParams(
      name: _name.trim(),
      description: _description.trim().isEmpty ? null : _description.trim(),
      startDate: formattedStartDate,
      contributionAmount: _montoCuota,
      numParticipants: _numParticipantes,
      numRounds: _numRounds,
      graceDays: _graceDays,
      hasDeadNumber: _hasDeadNumber,
      idTandaType: idTandaType,
    );

    final result = await crearTandaUseCase(params);

    return result.when(
      success: (tanda) {
        _createdTanda = tanda;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  /// Limpia los campos del formulario regresándolos a valores por defecto.
  void resetForm() {
    _name = '';
    _description = '';
    _startDate = DateTime.now().add(const Duration(days: 1));
    _montoCuota = 1000.0;
    _numParticipantes = 5;
    _numRounds = 1;
    _graceDays = 0;
    _hasDeadNumber = false;
    _isRandomAssignment = false;
    _periodicidad = PeriodicidadTanda.quincenal;
    _isLoading = false;
    _errorMessage = null;
    _createdTanda = null;
    recalcularPlan();
    notifyListeners();
  }
}
