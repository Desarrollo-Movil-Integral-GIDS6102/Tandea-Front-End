import 'package:equatable/equatable.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';

/// Entidad pura del dominio que modela el pago de un turno (`number`) en una tanda.
class PagoEntity extends Equatable {
  final int idPayment;
  final int idNumber;
  final MetodoPago metodoPago;
  final double transferAmount;
  final double cashAmount;
  final double totalAmount;

  /// `PENDIENTE`, `CONFIRMADO` o `RECHAZADO`.
  final String status;
  final bool confirmedByParticipant;
  final bool confirmedByAdmin;
  final bool ocrVerified;
  final double? ocrDetectedAmount;
  final String? evidenceUrl;

  /// Motivo que capturó el organizador al rechazar.
  final String? rejectionReason;
  final DateTime? createdAt;

  const PagoEntity({
    required this.idPayment,
    required this.idNumber,
    required this.metodoPago,
    required this.transferAmount,
    required this.cashAmount,
    required this.totalAmount,
    required this.status,
    this.confirmedByParticipant = false,
    this.confirmedByAdmin = false,
    this.ocrVerified = false,
    this.ocrDetectedAmount,
    this.evidenceUrl,
    this.rejectionReason,
    this.createdAt,
  });

  bool get estaPendiente => status.toUpperCase() == 'PENDIENTE';
  bool get estaConfirmado => status.toUpperCase() == 'CONFIRMADO';
  bool get estaRechazado => status.toUpperCase() == 'RECHAZADO';

  /// El organizador solo puede confirmar o rechazar un pago pendiente que aún no confirmó.
  bool get puedeRevisarse => estaPendiente && !confirmedByAdmin;

  @override
  List<Object?> get props => [
        idPayment,
        idNumber,
        metodoPago,
        transferAmount,
        cashAmount,
        totalAmount,
        status,
        confirmedByParticipant,
        confirmedByAdmin,
        ocrVerified,
        ocrDetectedAmount,
        evidenceUrl,
        rejectionReason,
        createdAt,
      ];
}
