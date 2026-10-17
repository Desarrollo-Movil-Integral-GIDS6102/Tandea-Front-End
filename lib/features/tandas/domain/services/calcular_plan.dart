import 'package:equatable/equatable.dart';

/// Periodicidad admitida en el sistema de tandas (AP-01).
enum PeriodicidadTanda {
  diaria('diaria', 'Diaria'),
  semanal('semanal', 'Semanal'),
  quincenal('quincenal', 'Quincenal'),
  mensual('mensual', 'Mensual');

  final String value;
  final String label;

  const PeriodicidadTanda(this.value, this.label);

  static PeriodicidadTanda fromString(String val) {
    return PeriodicidadTanda.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => PeriodicidadTanda.quincenal,
    );
  }
}

/// Parámetros de entrada para el cálculo financiero de la tanda.
class PlanTandaInput extends Equatable {
  final PeriodicidadTanda periodicidad;
  final double montoCuota;
  final int numParticipantes;
  final int numVueltas;
  final bool tieneNumeroMuerto;
  final DateTime fechaInicio;

  const PlanTandaInput({
    required this.periodicidad,
    required this.montoCuota,
    required this.numParticipantes,
    this.numVueltas = 1,
    this.tieneNumeroMuerto = false,
    required this.fechaInicio,
  });

  @override
  List<Object?> get props => [
        periodicidad,
        montoCuota,
        numParticipantes,
        numVueltas,
        tieneNumeroMuerto,
        fechaInicio,
      ];
}

/// Excepción de validación de parámetros para el cálculo del plan.
class PlanTandaInvalidoException implements Exception {
  final String mensaje;
  const PlanTandaInvalidoException(this.mensaje);

  @override
  String toString() => 'PlanTandaInvalidoException: $mensaje';
}

/// Resultado inmutable del plan financiero y calendario de la tanda.
class PlanTandaResult extends Equatable {
  final int totalNumeros;
  final int totalPagos;
  final int totalTurnos;
  final double montoPorTurno;
  final double montoTotalPorParticipante;
  final DateTime fechaFin;

  const PlanTandaResult({
    required this.totalNumeros,
    required this.totalPagos,
    required this.totalTurnos,
    required this.montoPorTurno,
    required this.montoTotalPorParticipante,
    required this.fechaFin,
  });

  @override
  List<Object?> get props => [
        totalNumeros,
        totalPagos,
        totalTurnos,
        montoPorTurno,
        montoTotalPorParticipante,
        fechaFin,
      ];
}

/// Función pura de dominio que espejea exactamente la lógica de negocio de
/// `Tandea-Back-End/src/tandas/domain/services/calcular-plan.ts` (AP-01).
///
/// Reglas de negocio:
/// 1. totalNumeros = numParticipantes + (tieneNumeroMuerto ? 1 : 0)
/// 2. totalPagos = totalNumeros * numVueltas
/// 3. totalTurnos = totalNumeros * numVueltas
/// 4. montoPorTurno = montoCuota * totalNumeros (operado en centavos enteros)
/// 5. montoTotalPorParticipante = montoCuota * totalPagos (operado en centavos enteros)
/// 6. fechaFin = fechaInicio + (totalTurnos - 1) periodos según periodicidad:
///    - diaria: +1 día por turno
///    - semanal: +7 días por turno
///    - quincenal: +15 días por turno
///    - mensual: +1 mes calendario (ajustando al último día si el mes destino tiene menos días)
PlanTandaResult calcularPlan(PlanTandaInput input) {
  // Validaciones estrictas de dominio
  if (input.numParticipantes < 2) {
    throw const PlanTandaInvalidoException(
      'El número de participantes debe ser un número entero mayor o igual a 2.',
    );
  }

  if (input.numVueltas < 1) {
    throw const PlanTandaInvalidoException(
      'El número de vueltas debe ser un número entero mayor o igual a 1.',
    );
  }

  if (input.montoCuota.isNaN || input.montoCuota.isInfinite || input.montoCuota <= 0) {
    throw const PlanTandaInvalidoException(
      'El monto de la cuota debe ser un número positivo mayor a 0.',
    );
  }

  // Cálculos de números y turnos
  final totalNumeros = input.numParticipantes + (input.tieneNumeroMuerto ? 1 : 0);
  final totalPagos = totalNumeros * input.numVueltas;
  final totalTurnos = totalNumeros * input.numVueltas;

  // Cálculos monetarios en centavos enteros para evitar imprecisión IEEE 754
  final cuotaCentavos = (input.montoCuota * 100).round();
  final montoPorTurnoCentavos = cuotaCentavos * totalNumeros;
  final montoTotalPorParticipanteCentavos = cuotaCentavos * totalPagos;

  final montoPorTurno = double.parse((montoPorTurnoCentavos / 100.0).toStringAsFixed(2));
  final montoTotalPorParticipante =
      double.parse((montoTotalPorParticipanteCentavos / 100.0).toStringAsFixed(2));

  // Cálculo de fechaFin (fecha del último turno = fechaInicio + (totalTurnos - 1) periodos)
  final periodos = totalTurnos - 1;
  final fechaInicio = DateTime(
    input.fechaInicio.year,
    input.fechaInicio.month,
    input.fechaInicio.day,
  );

  DateTime fechaFin = fechaInicio;

  if (periodos > 0) {
    switch (input.periodicidad) {
      case PeriodicidadTanda.diaria:
        fechaFin = fechaInicio.add(Duration(days: periodos));
        break;
      case PeriodicidadTanda.semanal:
        fechaFin = fechaInicio.add(Duration(days: periodos * 7));
        break;
      case PeriodicidadTanda.quincenal:
        fechaFin = fechaInicio.add(Duration(days: periodos * 15));
        break;
      case PeriodicidadTanda.mensual:
        // Meses en Dart van del 1 al 12. Convertimos a base 0 para el cálculo matemático
        final zeroMonth = fechaInicio.month - 1;
        final targetYear = fechaInicio.year + ((zeroMonth + periodos) ~/ 12);
        final targetMonthZero = (zeroMonth + periodos) % 12;
        final targetMonth = targetMonthZero + 1;

        // Último día del mes de destino (en Dart, día 0 del mes siguiente da el último día del mes actual)
        final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay = fechaInicio.day < lastDayOfTargetMonth
            ? fechaInicio.day
            : lastDayOfTargetMonth;

        fechaFin = DateTime(targetYear, targetMonth, targetDay);
        break;
    }
  }

  return PlanTandaResult(
    totalNumeros: totalNumeros,
    totalPagos: totalPagos,
    totalTurnos: totalTurnos,
    montoPorTurno: montoPorTurno,
    montoTotalPorParticipante: montoTotalPorParticipante,
    fechaFin: fechaFin,
  );
}

/// Versión tolerante para la UI reactiva: si los datos son inválidos o parciales,
/// retorna `null` en lugar de lanzar una excepción.
PlanTandaResult? calcularPlanSafe(PlanTandaInput input) {
  try {
    return calcularPlan(input);
  } catch (_) {
    return null;
  }
}
