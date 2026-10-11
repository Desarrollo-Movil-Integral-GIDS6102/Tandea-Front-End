import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Proveedor de estado para la gestión de tandas.
class TandasProvider extends ChangeNotifier {
  final TandasRepository _tandasRepository;

  EstadoCarga _estado = EstadoCarga.inicial;
  List<TandaEntity> _tandas = const [];
  TandaEntity? _selectedTanda;
  String? _errorMessage;

  TandasProvider({required TandasRepository tandasRepository})
      : _tandasRepository = tandasRepository;

  EstadoCarga get estado => _estado;
  List<TandaEntity> get tandas => _tandas;
  TandaEntity? get selectedTanda => _selectedTanda;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTandas() async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await _tandasRepository.getTandas();
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

  Future<void> fetchTandaById(String id) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await _tandasRepository.getTandaById(id);
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
