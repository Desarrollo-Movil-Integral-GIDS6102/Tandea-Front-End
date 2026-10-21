import 'package:flutter/foundation.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_tanda_por_codigo_usecase.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';

/// Proveedor de estado para el flujo de Unirse a una Tanda.
///
/// Gestiona la validación local de código mediante regex de 8 a 10 caracteres,
/// la consulta previa de la tanda y el envío de unión con o sin turno seleccionado,
/// exponiendo de manera transparente los mensajes de error retornados por el backend.
class UnirseTandaProvider extends ChangeNotifier {
  final ObtenerTandaPorCodigoUseCase obtenerTandaPorCodigoUseCase;
  final UnirseTandaUseCase unirseTandaUseCase;

  UnirseTandaProvider({
    required this.obtenerTandaPorCodigoUseCase,
    required this.unirseTandaUseCase,
  });

  /// Longitud mínima permitida para el código de invitación.
  static const int codigoMinLength = 8;

  /// Longitud máxima permitida para el código de invitación.
  static const int codigoMaxLength = 10;

  /// Expresión regular que exige entre 8 y 10 caracteres alfanuméricos (incluye guión opcional).
  static final RegExp regexCodigo = RegExp(r'^[A-Z0-9\-]{8,10}$');

  // --- Estado interno ---
  String _inviteCode = '';
  bool _isLoading = false;
  String? _validationError;
  String? _backendError;
  TandaEntity? _foundTanda;
  UnirseTandaResult? _joinResult;
  int? _selectedNumber;

  // --- Getters ---
  String get inviteCode => _inviteCode;
  bool get isLoading => _isLoading;
  String? get validationError => _validationError;
  String? get backendError => _backendError;
  TandaEntity? get foundTanda => _foundTanda;
  UnirseTandaResult? get joinResult => _joinResult;
  int? get selectedNumber => _selectedNumber;

  /// Retorna `true` si la tanda obtenida es por elección (idTandaType == 1).
  /// Si es Sorteo (idTandaType == 2 u otro), no es por elección.
  bool get isPorEleccion => _foundTanda?.idTandaType == 1;

  // --- Modificadores de estado ---

  void setInviteCode(String code) {
    _inviteCode = code.toUpperCase().trim();
    _validationError = null;
    _backendError = null;
    notifyListeners();
  }

  void setSelectedNumber(int number) {
    _selectedNumber = number;
    _backendError = null;
    notifyListeners();
  }

  void clearErrors() {
    _validationError = null;
    _backendError = null;
    notifyListeners();
  }

  /// Valida localmente el código antes de emitir cualquier petición HTTP al API.
  /// Retorna `true` si cumple con la longitud y formato de 8 a 10 caracteres.
  bool validarCodigoLocal() {
    final codigo = _inviteCode.trim();

    if (codigo.isEmpty) {
      _validationError = 'Ingresa el código de invitación de la tanda.';
      notifyListeners();
      return false;
    }

    if (codigo.length < codigoMinLength ||
        codigo.length > codigoMaxLength ||
        !regexCodigo.hasMatch(codigo)) {
      _validationError =
          'El código debe tener entre $codigoMinLength y $codigoMaxLength caracteres (ej. TND-7K9A2B).';
      notifyListeners();
      return false;
    }

    _validationError = null;
    return true;
  }

  /// Consulta la tanda por su código en el backend: `GET /tandas/codigo/:inviteCode`.
  /// Si la validación regex falla, NO realiza la llamada al API.
  Future<TandaEntity?> consultarTanda() async {
    if (!validarCodigoLocal()) {
      return null;
    }

    _isLoading = true;
    _backendError = null;
    _foundTanda = null;
    notifyListeners();

    final result = await obtenerTandaPorCodigoUseCase(_inviteCode.trim());

    return result.when(
      success: (tanda) {
        _foundTanda = tanda;
        _isLoading = false;
        _backendError = null;
        notifyListeners();
        return tanda;
      },
      failure: (failure) {
        _isLoading = false;
        _backendError = failure.message;
        notifyListeners();
        return null;
      },
    );
  }

  /// Ejecuta la unión a la tanda: `POST /tandas/unirse`.
  /// Acepta un `selectedNumber` opcional si la tanda es por elección.
  Future<UnirseTandaResult?> unirse({int? selectedNumber}) async {
    final numero = selectedNumber ?? _selectedNumber;

    _isLoading = true;
    _backendError = null;
    notifyListeners();

    final params = JoinTandaParams(
      inviteCode: _inviteCode.trim(),
      selectedNumber: numero,
    );

    final result = await unirseTandaUseCase(params);

    return result.when(
      success: (joinRes) {
        _joinResult = joinRes;
        _isLoading = false;
        _backendError = null;
        notifyListeners();
        return joinRes;
      },
      failure: (failure) {
        _isLoading = false;
        _backendError = failure.message;
        notifyListeners();
        return null;
      },
    );
  }

  /// Limpia todo el estado para un nuevo intento o flujo.
  void reset() {
    _inviteCode = '';
    _isLoading = false;
    _validationError = null;
    _backendError = null;
    _foundTanda = null;
    _joinResult = null;
    _selectedNumber = null;
    notifyListeners();
  }
}
