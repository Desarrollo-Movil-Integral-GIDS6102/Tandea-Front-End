import 'package:equatable/equatable.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';

/// Datos para registrar el pago de un turno (AP-03).
class RegistrarPagoParams extends Equatable {
  final int idNumber;
  final MetodoPago metodoPago;

  /// Parte por transferencia. Si es null, no se envía.
  final double? transferAmount;

  /// Parte en efectivo. Si es null, no se envía.
  final double? cashAmount;
  final ComprobanteArchivo? comprobante;

  const RegistrarPagoParams({
    required this.idNumber,
    required this.metodoPago,
    this.transferAmount,
    this.cashAmount,
    this.comprobante,
  });

  @override
  List<Object?> get props => [idNumber, metodoPago, transferAmount, cashAmount, comprobante];
}

/// Contrato abstracto del repositorio de pagos en la capa de dominio.
abstract class PagoRepository {
  Future<Result<List<PagoEntity>>> getPagosByTanda(String tandaId);

  Future<Result<PagoEntity>> registrarPago(RegistrarPagoParams params);
}
