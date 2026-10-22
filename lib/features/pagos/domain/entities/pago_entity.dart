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
    this.createdAt,
  });

  bool get estaPendiente => status.toUpperCase() == 'PENDIENTE';

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
        createdAt,
      ];
}
