import 'package:equatable/equatable.dart';

/// Número (turno) apartado dentro de una tanda.
class NumeroTanda extends Equatable {
  /// `id_number`: lo que espera el backend para registrar un pago.
  final int idNumber;
  final int numberValue;
  final int roundNumber;
  final bool isDeadNumber;
  final String? userName;

  const NumeroTanda({
    required this.idNumber,
    required this.numberValue,
    this.roundNumber = 1,
    this.isDeadNumber = false,
    this.userName,
  });

  factory NumeroTanda.fromJson(Map<String, dynamic> json) {
    return NumeroTanda(
      idNumber: (json['idNumber'] as num).toInt(),
      numberValue: (json['numberValue'] as num).toInt(),
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      isDeadNumber: json['isDeadNumber'] as bool? ?? false,
      userName: json['userName'] as String?,
    );
  }

  static List<NumeroTanda> listFromJson(dynamic raw) => raw is List
      ? raw.whereType<Map<String, dynamic>>().map(NumeroTanda.fromJson).toList()
      : const [];

  @override
  List<Object?> get props => [idNumber, numberValue, roundNumber, isDeadNumber, userName];
}
