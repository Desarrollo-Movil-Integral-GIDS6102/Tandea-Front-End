import 'package:flutter/foundation.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/origen_imagen.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';
import 'package:tandea/features/pagos/domain/usecases/seleccionar_comprobante_usecase.dart';

/// Proveedor de estado para la gestión de pagos.
class PagoProvider extends ChangeNotifier {
  final PagoRepository pagoRepository;
  final SeleccionarComprobanteUseCase? seleccionarComprobanteUseCase;

  EstadoCarga _estado = EstadoCarga.inicial;
  List<PagoEntity> _pagos = const [];
  String? _errorMessage;

  // Estado del formulario "Registrar pago" (AP-03 y AP-04)
  MetodoPago _metodoPago = MetodoPago.transferencia;
  double? _montoTransferencia;
  double? _montoEfectivo;
  ComprobanteArchivo? _comprobante;
  PagoEntity? _pagoRegistrado;

  bool _procesandoComprobante = false;

  PagoProvider({
    required this.pagoRepository,
    this.seleccionarComprobanteUseCase,
  });

  EstadoCarga get estado => _estado;
  List<PagoEntity> get pagos => _pagos;
  String? get errorMessage => _errorMessage;

  MetodoPago get metodoPago => _metodoPago;
  double? get montoTransferencia => _montoTransferencia;
  double? get montoEfectivo => _montoEfectivo;
  ComprobanteArchivo? get comprobante => _comprobante;
  PagoEntity? get pagoRegistrado => _pagoRegistrado;
  bool get enviando => _estado == EstadoCarga.cargando;
  bool get procesandoComprobante => _procesandoComprobante;

  /// Indica si la suma del pago híbrido coincide con la cuota.
  // TODO: SP-2-[FE-PAGO] Deshabilitar "Ya pagué" si la suma híbrida no coincide con la cuota
  // (comparar en centavos con montoACentavos y recibir la cuota).
  bool get sumaValida => true;

  /// Determina si las condiciones del formulario permiten intentar el registro.
  bool get puedeRegistrar => !enviando && !_procesandoComprobante && sumaValida;

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
    _errorMessage = null;
    notifyListeners();
  }

  void eliminarComprobante() {
    _comprobante = null;
    notifyListeners();
  }

  /// Captura desde cámara o selecciona de galería el comprobante de pago.
  /// Maneja estados de carga, compresión y errores.
  Future<void> capturarComprobante(OrigenImagen origen) async {
    if (seleccionarComprobanteUseCase == null || _procesandoComprobante) {
      return;
    }

    _procesandoComprobante = true;
    _errorMessage = null;
    notifyListeners();

    final result = await seleccionarComprobanteUseCase!(origen);

    result.when(
      success: (archivo) {
        if (archivo != null) {
          _comprobante = archivo;
        }
        // Si el usuario canceló la selección, archivo es null; conservamos
        // el comprobante previo y no generamos error.
        _procesandoComprobante = false;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _procesandoComprobante = false;
        notifyListeners();
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Registra el pago del turno [idNumber]. En transferencia y efectivo el monto
  /// enviado es la [cuota]; en híbrido, los montos capturados por el usuario.
  ///
  /// Devuelve `true` si el backend lo aceptó. Ignora llamadas mientras ya hay un envío en curso
  /// o mientras se está procesando la imagen del comprobante.
  Future<bool> registrarPago({
    required int idNumber,
    required double cuota,
  }) async {
    if (enviando || _procesandoComprobante) {
      return false;
    }

    if (_comprobante != null && _comprobante!.bytes.isEmpty) {
      _errorMessage = 'El comprobante seleccionado está vacío o no es válido.';
      _estado = EstadoCarga.error;
      notifyListeners();
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
