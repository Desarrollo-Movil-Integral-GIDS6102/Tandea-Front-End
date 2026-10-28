import 'package:flutter/foundation.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Estado de la pantalla Detalle de tanda (`GET /tandas/:id`).
class TandaDetalleProvider extends ChangeNotifier {
  final TandasRepository tandasRepository;

  TandaDetalleProvider({required this.tandasRepository});

  TandaEntity? _tanda;
  bool _cargando = false;
  bool _iniciando = false;
  String? _errorMessage;

  TandaEntity? get tanda => _tanda;
  bool get cargando => _cargando;
  bool get iniciando => _iniciando;
  String? get errorMessage => _errorMessage;

  Future<void> cargar(String id) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    final result = await tandasRepository.getTandaById(id);
    result.when(
      success: (data) => _tanda = data,
      failure: (failure) => _errorMessage = failure.message,
    );
    _cargando = false;
    notifyListeners();
  }

  /// El organizador inicia la tanda; desde ese momento se habilitan los pagos.
  Future<bool> iniciar() async {
    final actual = _tanda;
    if (actual == null || _iniciando) return false;

    _iniciando = true;
    _errorMessage = null;
    notifyListeners();

    final result = await tandasRepository.iniciarTanda(actual.id);
    final ok = result.when(
      success: (_) => true,
      failure: (failure) {
        _errorMessage = failure.message;
        return false;
      },
    );
    _iniciando = false;
    if (ok) {
      await cargar(actual.id);
    } else {
      notifyListeners();
    }
    return ok;
  }
}
