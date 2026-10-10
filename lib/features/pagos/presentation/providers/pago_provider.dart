import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';

/// Proveedor de estado para la gestión de pagos.
class PagoProvider extends ChangeNotifier {
  final PagoRepository _pagoRepository;

  EstadoCarga _estado = EstadoCarga.inicial;
  List<PagoEntity> _pagos = const [];
  String? _errorMessage;

  PagoProvider({required PagoRepository pagoRepository})
      : _pagoRepository = pagoRepository;

  EstadoCarga get estado => _estado;
  List<PagoEntity> get pagos => _pagos;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPagos(String tandaId) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await _pagoRepository.getPagosByTanda(tandaId);
    result.when(
      success: (data) {
        _pagos = data;
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

  Future<bool> registrarPago({
    required String tandaId,
    required double monto,
    String? comprobanteUrl,
  }) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await _pagoRepository.registrarPago(
      tandaId: tandaId,
      monto: monto,
      comprobanteUrl: comprobanteUrl,
    );

    return result.when(
      success: (pago) {
        _pagos = [pago, ..._pagos];
        _estado = EstadoCarga.exito;
        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _estado = EstadoCarga.error;
        notifyListeners();
        return false;
      },
    );
  }
}
