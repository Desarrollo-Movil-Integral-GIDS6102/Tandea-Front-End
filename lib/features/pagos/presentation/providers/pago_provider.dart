import 'package:flutter/foundation.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';

/// Proveedor de estado para la gestión de pagos.
class PagoProvider extends ChangeNotifier {
  final PagoRepository pagoRepository;

  EstadoCarga _estado = EstadoCarga.inicial;
  List<PagoEntity> _pagos = const [];
  String? _errorMessage;

  // Estado del formulario "Registrar pago" (AP-03)
  MetodoPago _metodoPago = MetodoPago.transferencia;
  double? _montoTransferencia;
  double? _montoEfectivo;
  ComprobanteArchivo? _comprobante;
  PagoEntity? _pagoRegistrado;

  PagoProvider({required this.pagoRepository});

  EstadoCarga get estado => _estado;
  List<PagoEntity> get pagos => _pagos;
  String? get errorMessage => _errorMessage;

  MetodoPago get metodoPago => _metodoPago;
  double? get montoTransferencia => _montoTransferencia;
  double? get montoEfectivo => _montoEfectivo;
  ComprobanteArchivo? get comprobante => _comprobante;
  PagoEntity? get pagoRegistrado => _pagoRegistrado;
  bool get enviando => _estado == EstadoCarga.cargando;

  /// En híbrido, ambos montos deben ser mayores a cero y sumar exactamente la [cuota]
  /// (comparado en centavos). En transferencia y efectivo el monto es la cuota.
  bool sumaValida(double cuota) {
    if (!_metodoPago.esHibrido) {
      return true;
    }
    final transferencia = _montoTransferencia ?? 0;
    final efectivo = _montoEfectivo ?? 0;
    return transferencia > 0 &&
        efectivo > 0 &&
        montoACentavos(transferencia) + montoACentavos(efectivo) == montoACentavos(cuota);
  }

  /// Transferencia e híbrido exigen comprobante; efectivo no.
  bool get comprobanteListo => !_metodoPago.requiereComprobante || _comprobante != null;

  /// "Ya pagué" solo se habilita con la suma correcta y el comprobante adjunto.
  bool puedeEnviar(double cuota) => !enviando && sumaValida(cuota) && comprobanteListo;

  Future<void> fetchPagos(String tandaId) async {
    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await pagoRepository.getPagosByTanda(tandaId);
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

  void seleccionarMetodo(MetodoPago metodo) {
    if (_metodoPago == metodo) {
      return;
    }
    _metodoPago = metodo;
    _errorMessage = null;
    notifyListeners();
  }

  void actualizarMontoTransferencia(String texto) {
    _montoTransferencia = parsearMonto(texto);
    notifyListeners();
  }

  void actualizarMontoEfectivo(String texto) {
    _montoEfectivo = parsearMonto(texto);
    notifyListeners();
  }

  void seleccionarComprobante(ComprobanteArchivo? comprobante) {
    _comprobante = comprobante;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Registra el pago del turno [idNumber]. En transferencia y efectivo el monto
  /// enviado es la [cuota]; en híbrido, los montos capturados por el usuario.
  ///
  /// Devuelve `true` si el backend lo aceptó. Ignora llamadas mientras ya hay un envío en curso.
  Future<bool> registrarPago({
    required int idNumber,
    required double cuota,
  }) async {
    if (enviando) {
      return false;
    }

    final params = RegistrarPagoParams(
      idNumber: idNumber,
      metodoPago: _metodoPago,
      transferAmount: switch (_metodoPago) {
        MetodoPago.transferencia => cuota,
        MetodoPago.hibrido => _montoTransferencia,
        MetodoPago.efectivo => null,
      },
      cashAmount: switch (_metodoPago) {
        MetodoPago.efectivo => cuota,
        MetodoPago.hibrido => _montoEfectivo,
        MetodoPago.transferencia => null,
      },
      comprobante: _comprobante,
    );

    _estado = EstadoCarga.cargando;
    _errorMessage = null;
    notifyListeners();

    final result = await pagoRepository.registrarPago(params);

    return result.when(
      success: (pago) {
        _pagoRegistrado = pago;
        _pagos = [..._pagos, pago];
        _estado = EstadoCarga.exito;
        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorMessage = mensajeErrorRegistro(failure);
        _estado = EstadoCarga.error;
        notifyListeners();
        return false;
      },
    );
  }

  /// Traduce la falla del backend a un mensaje amigable en español.
  static String mensajeErrorRegistro(Failure failure) {
    const mensajeReintentar = 'No pudimos enviar tu pago. Intenta de nuevo.';

    if (failure is NetworkFailure) {
      return mensajeReintentar;
    }
    if (failure is UnauthorizedFailure) {
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    if (failure is ServerFailure) {
      final detalle = failure.message.trim();
      switch (failure.statusCode) {
        case 400:
        case 422:
          return detalle.isNotEmpty ? detalle : 'Revisa los montos o el comprobante.';
        case 403:
          return 'No puedes registrar pagos en este número.';
        case 404:
          return 'No encontramos este turno o su tanda.';
        case 409:
          return 'Este pago ya fue registrado.';
        case 413:
          return 'El comprobante supera el tamaño máximo de 10 MB.';
      }
    }
    return mensajeReintentar;
  }
}
