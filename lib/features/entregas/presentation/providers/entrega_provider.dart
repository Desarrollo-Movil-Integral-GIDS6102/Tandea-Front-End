import 'package:flutter/foundation.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/entregas/domain/entities/entrega_entity.dart';
import 'package:tandea/features/entregas/domain/repositories/entrega_repository.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';

/// Estado de las pantallas Registrar entrega y Confirmar recepción.
class EntregaProvider extends ChangeNotifier {
  final EntregaRepository entregaRepository;

  EntregaProvider({required this.entregaRepository});

  EntregaEntity? _entrega;
  ComprobanteArchivo? _evidencia;
  bool _cargando = false;
  bool _enviando = false;
  String? _errorMessage;

  EntregaEntity? get entrega => _entrega;
  ComprobanteArchivo? get evidencia => _evidencia;
  bool get cargando => _cargando;
  bool get enviando => _enviando;
  String? get errorMessage => _errorMessage;

  void seleccionarEvidencia(ComprobanteArchivo? evidencia) {
    _evidencia = evidencia;
    notifyListeners();
  }

  Future<void> cargar(int idPayout) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    final result = await entregaRepository.obtener(idPayout);
    result.when(
      success: (data) => _entrega = data,
      failure: (failure) => _errorMessage = failure.message,
    );
    _cargando = false;
    notifyListeners();
  }

  Future<bool> registrar({
    required int idNumber,
    required double transferencia,
    required double efectivo,
  }) async {
    final evidencia = _evidencia;
    if (evidencia == null) return false;
    return _enviar(() => entregaRepository.registrar(
          idNumber: idNumber,
          transferencia: transferencia,
          efectivo: efectivo,
          evidencia: evidencia,
        ));
  }

  Future<bool> confirmar(int idPayout) => _enviar(() => entregaRepository.confirmar(idPayout));

  Future<bool> reportarProblema(int idPayout, String motivo) =>
      _enviar(() => entregaRepository.reportarProblema(idPayout, motivo));

  Future<bool> _enviar<T>(Future<Result<T>> Function() accion) async {
    if (_enviando) return false;
    _enviando = true;
    _errorMessage = null;
    notifyListeners();

    final result = await accion();
    final ok = result.when(
      success: (data) {
        if (data is EntregaEntity) _entrega = data;
        return true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
        return false;
      },
    );
    _enviando = false;
    notifyListeners();
    return ok;
  }
}
