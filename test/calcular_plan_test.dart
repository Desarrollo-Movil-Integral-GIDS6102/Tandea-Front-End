import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/features/tandas/domain/services/calcular_plan.dart';

void main() {
  group('calcularPlan - Espejo exacto del backend (AP-01)', () {
    final fechaInicio = DateTime(2026, 1, 1);

    test('fórmula matemática: cuota 500, 4 participantes, 1 vuelta, quincenal, sin número muerto', () {
      final input = PlanTandaInput(
        periodicidad: PeriodicidadTanda.quincenal,
        montoCuota: 500.0,
        numParticipantes: 4,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: fechaInicio,
      );

      final resultado = calcularPlan(input);

      expect(resultado.totalNumeros, equals(4));
      expect(resultado.totalPagos, equals(4));
      expect(resultado.totalTurnos, equals(4));
      expect(resultado.montoPorTurno, equals(2000.0));
      expect(resultado.montoTotalPorParticipante, equals(2000.0));
      // 4 turnos -> periodos = 3 -> 3 * 15 = 45 días
      expect(resultado.fechaFin, equals(DateTime(2026, 2, 15)));
    });

    test('fórmula matemática con número muerto: cuota 500, 4 participantes, 1 vuelta, quincenal', () {
      final input = PlanTandaInput(
        periodicidad: PeriodicidadTanda.quincenal,
        montoCuota: 500.0,
        numParticipantes: 4,
        numVueltas: 1,
        tieneNumeroMuerto: true,
        fechaInicio: fechaInicio,
      );

      final resultado = calcularPlan(input);

      expect(resultado.totalNumeros, equals(5)); // 4 + 1
      expect(resultado.totalPagos, equals(5));
      expect(resultado.totalTurnos, equals(5));
      expect(resultado.montoPorTurno, equals(2500.0));
      expect(resultado.montoTotalPorParticipante, equals(2500.0));
      // 5 turnos -> periodos = 4 -> 4 * 15 = 60 días
      expect(resultado.fechaFin, equals(DateTime(2026, 3, 2)));
    });

    test('periodicidad diaria sin número muerto (5 participantes)', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.diaria,
        montoCuota: 100.0,
        numParticipantes: 5,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: fechaInicio,
      ));

      expect(res.totalNumeros, equals(5));
      expect(res.totalTurnos, equals(5));
      expect(res.montoPorTurno, equals(500.0));
      // 5 turnos diaria -> fechaInicio + 4 días
      expect(res.fechaFin, equals(DateTime(2026, 1, 5)));
    });

    test('periodicidad diaria con número muerto (5 participantes)', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.diaria,
        montoCuota: 100.0,
        numParticipantes: 5,
        numVueltas: 1,
        tieneNumeroMuerto: true,
        fechaInicio: fechaInicio,
      ));

      expect(res.totalNumeros, equals(6));
      expect(res.totalTurnos, equals(6));
      expect(res.montoPorTurno, equals(600.0));
      expect(res.fechaFin, equals(DateTime(2026, 1, 6)));
    });

    test('periodicidad semanal sin número muerto (4 participantes)', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.semanal,
        montoCuota: 200.0,
        numParticipantes: 4,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: fechaInicio,
      ));

      expect(res.totalTurnos, equals(4));
      // 4 turnos semanal -> fechaInicio + 3 * 7 días = 21 días
      expect(res.fechaFin, equals(DateTime(2026, 1, 22)));
    });

    test('periodicidad semanal con número muerto (4 participantes)', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.semanal,
        montoCuota: 200.0,
        numParticipantes: 4,
        numVueltas: 1,
        tieneNumeroMuerto: true,
        fechaInicio: fechaInicio,
      ));

      expect(res.totalTurnos, equals(5));
      // 5 turnos semanal -> fechaInicio + 4 * 7 días = 28 días
      expect(res.fechaFin, equals(DateTime(2026, 1, 29)));
    });

    test('periodicidad mensual sin número muerto (4 participantes)', () {
      final fechaMarzo = DateTime(2026, 3, 10);
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.mensual,
        montoCuota: 1000.0,
        numParticipantes: 4,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: fechaMarzo,
      ));

      expect(res.totalTurnos, equals(4));
      // 4 turnos mensual -> + 3 meses = 10 de Junio
      expect(res.fechaFin, equals(DateTime(2026, 6, 10)));
    });

    test('periodicidad mensual con número muerto (4 participantes)', () {
      final fechaMarzo = DateTime(2026, 3, 10);
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.mensual,
        montoCuota: 1000.0,
        numParticipantes: 4,
        numVueltas: 1,
        tieneNumeroMuerto: true,
        fechaInicio: fechaMarzo,
      ));

      expect(res.totalTurnos, equals(5));
      // 5 turnos mensual -> + 4 meses = 10 de Julio
      expect(res.fechaFin, equals(DateTime(2026, 7, 10)));
    });

    test('múltiples vueltas (numVueltas = 3, semanal, 5 participantes)', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.semanal,
        montoCuota: 500.0,
        numParticipantes: 5,
        numVueltas: 3,
        tieneNumeroMuerto: false,
        fechaInicio: fechaInicio,
      ));

      expect(res.totalNumeros, equals(5));
      expect(res.totalPagos, equals(15));
      expect(res.totalTurnos, equals(15));
      expect(res.montoPorTurno, equals(2500.0));
      expect(res.montoTotalPorParticipante, equals(7500.0));
      // 15 turnos -> 14 * 7 = 98 días
      expect(res.fechaFin, equals(DateTime(2026, 4, 9)));
    });

    test('ajuste de mes sin 31 días (no bisiesto): 31 Ene 2026 + 1 mes -> 28 Feb 2026', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.mensual,
        montoCuota: 500.0,
        numParticipantes: 2,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: DateTime(2026, 1, 31),
      ));

      expect(res.fechaFin, equals(DateTime(2026, 2, 28)));
    });

    test('ajuste de mes bisiesto: 31 Ene 2024 + 1 mes -> 29 Feb 2024', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.mensual,
        montoCuota: 500.0,
        numParticipantes: 2,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: DateTime(2024, 1, 31),
      ));

      expect(res.fechaFin, equals(DateTime(2024, 2, 29)));
    });

    test('ajuste de mes con 30 días: 31 Ago 2026 + 1 mes -> 30 Sep 2026', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.mensual,
        montoCuota: 500.0,
        numParticipantes: 2,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: DateTime(2026, 8, 31),
      ));

      expect(res.fechaFin, equals(DateTime(2026, 9, 30)));
    });

    test('ajuste que cambia de año: 30 Nov 2026 + 2 meses -> 30 Ene 2027', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.mensual,
        montoCuota: 500.0,
        numParticipantes: 3,
        numVueltas: 1,
        tieneNumeroMuerto: false,
        fechaInicio: DateTime(2026, 11, 30),
      ));

      expect(res.fechaFin, equals(DateTime(2027, 1, 30)));
    });

    test('precisión decimal monetaria en centavos', () {
      final res = calcularPlan(PlanTandaInput(
        periodicidad: PeriodicidadTanda.semanal,
        montoCuota: 100.55,
        numParticipantes: 4,
        numVueltas: 2,
        tieneNumeroMuerto: false,
        fechaInicio: fechaInicio,
      ));

      expect(res.montoPorTurno, equals(402.20));
      expect(res.montoTotalPorParticipante, equals(804.40));
    });

    test('validaciones: lanza PlanTandaInvalidoException en valores no permitidos', () {
      expect(
        () => calcularPlan(PlanTandaInput(
          periodicidad: PeriodicidadTanda.diaria,
          montoCuota: 100.0,
          numParticipantes: 1, // Mínimo 2
          fechaInicio: fechaInicio,
        )),
        throwsA(isA<PlanTandaInvalidoException>()),
      );

      expect(
        () => calcularPlan(PlanTandaInput(
          periodicidad: PeriodicidadTanda.diaria,
          montoCuota: 0, // Positivo requerido
          numParticipantes: 4,
          fechaInicio: fechaInicio,
        )),
        throwsA(isA<PlanTandaInvalidoException>()),
      );

      expect(
        () => calcularPlan(PlanTandaInput(
          periodicidad: PeriodicidadTanda.diaria,
          montoCuota: 100.0,
          numParticipantes: 4,
          numVueltas: 0, // Mínimo 1
          fechaInicio: fechaInicio,
        )),
        throwsA(isA<PlanTandaInvalidoException>()),
      );
    });

    test('calcularPlanSafe retorna null ante datos no válidos en vez de lanzar excepción', () {
      final res = calcularPlanSafe(PlanTandaInput(
        periodicidad: PeriodicidadTanda.diaria,
        montoCuota: 0,
        numParticipantes: 1,
        fechaInicio: fechaInicio,
      ));

      expect(res, isNull);
    });
  });
}
