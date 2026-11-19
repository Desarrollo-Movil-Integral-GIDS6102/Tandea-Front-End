import 'package:flutter/foundation.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository adminRepository;

  AdminProvider({required this.adminRepository});

  AdminMetricasEntity? _metricas;
  bool _isLoadingMetricas = false;
  String? _errorMetricas;

  AdminMetricasEntity? get metricas => _metricas;
  bool get isLoadingMetricas => _isLoadingMetricas;
  bool get isLoading => _isLoadingMetricas;
  String? get errorMetricas => _errorMetricas;
  String? get errorMessage => _errorMetricas;

  /// Carga o refresca las métricas globales del administrador (`GET /admin/metricas`).
  Future<void> cargarMetricas() async {
    _isLoadingMetricas = true;
    _errorMetricas = null;
    notifyListeners();

    final result = await adminRepository.obtenerMetricas();
    result.when(
      success: (data) {
        _metricas = data;
        _errorMetricas = null;
      },
      failure: (failure) {
        _errorMetricas = failure.message;
      },
    );

    _isLoadingMetricas = false;
    notifyListeners();
  }
}
