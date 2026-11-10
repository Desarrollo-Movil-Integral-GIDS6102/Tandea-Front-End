import 'package:flutter/foundation.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';

/// Acción del organizador que está en curso.
enum AccionRevision { ninguna, confirmando, rechazando }

/// Estado de la pantalla "Revisar pago" (AP-05): carga el pago con su comprobante
/// y resultado OCR, y lo confirma o rechaza.
class RevisarPagoProvider extends ChangeNotifier {
  final PagoRepository pagoRepository;

  EstadoCarga _estado = EstadoCarga.inicial;
  PagoEntity? _pago;
  String? _errorMessage;
  AccionRevision _accion = AccionRevision.ninguna;

  RevisarPagoProvider({required this.pagoRepository, PagoEntity? pagoInicial}) : _pago = pagoInicial;

  EstadoCarga get estado => _estado;
  PagoEntity? get pago => _pago;
  String? get errorMessage => _errorMessage;
  AccionRevision get accion => _accion;

  bool get cargando => _estado == EstadoCarga.cargando;
  bool get cargaFallida => _estado == EstadoCarga.error;
  bool get procesando => _accion != AccionRevision.ninguna;

  /// Los botones se habilitan con un pago pendiente y sin otra acción en curso.
  bool get puedeRevisar => !procesando && (_pago?.puedeRevisarse ?? false);

  Future<void> cargar(int idPayment) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await pagoRepository.obtenerPago(idPayment);
    result.when(
      success: (data) {
        _pago = data;
        _estado = EstadoCarga.exito;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = mensajeError(failure);
        _estado = EstadoCarga.error;
        notifyListeners();
      },
    );
  }

  /// Devuelve `true` si el backend confirmó el pago.
  Future<bool> confirmar() {
    final pago = _pago;
    if (pago == null || !puedeRevisar) {
      return Future.value(false);
    }
    return _ejecutar(AccionRevision.confirmando, () => pagoRepository.confirmarPago(pago.idPayment));
  }

  /// Devuelve `true` si el backend rechazó el pago con el [motivo].
  Future<bool> rechazar(String motivo) {
    final pago = _pago;
    if (pago == null || !puedeRevisar || !motivoValido(motivo)) {
      return Future.value(false);
    }
    return _ejecutar(AccionRevision.rechazando, () => pagoRepository.rechazarPago(pago.idPayment, motivo.trim()));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _ejecutar(AccionRevision accion, Future<Result<PagoEntity>> Function() llamada) async {
    _accion = accion;
    _errorMessage = null;
    notifyListeners();

    final result = await llamada();
    return result.when(
      success: (data) {
        _pago = data;
        _accion = AccionRevision.ninguna;
        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = mensajeError(failure);
        _accion = AccionRevision.ninguna;
        notifyListeners();
        return false;
      },
    );
  }

  /// Mismas reglas que el backend: de 5 a 500 caracteres sin contar espacios a los lados.
  static bool motivoValido(String motivo) {
    final largo = motivo.trim().length;
    return largo >= 5 && largo <= 500;
  }

  static String mensajeError(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No pudimos conectar con el servidor. Intenta de nuevo.';
    }
    if (failure is UnauthorizedFailure) {
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    if (failure is ServerFailure) {
      final detalle = failure.message.trim();
      switch (failure.statusCode) {
        case 403:
          return 'Solo el organizador de la tanda puede revisar este pago.';
        case 404:
          return 'No encontramos este pago.';
        case 409:
        case 422:
          return detalle.isNotEmpty ? detalle : 'Este pago ya fue revisado.';
      }
    }
    return 'No pudimos completar la acción. Intenta de nuevo.';
  }
}
