import 'package:equatable/equatable.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

/// Tipo de evento marcado en el calendario de la tanda (AP-06).
enum TipoMarcadorCalendario {
  pago,
  cobro,
}

/// Un turno dentro del calendario de la tanda (`GET /tandas/:id/calendario`).
class TurnoCalendario extends Equatable {
  final int turno;
  final int vuelta;
  final int numero;
  final bool esNumeroMuerto;
  final int? idUser;
  final String? nombreUsuario;

  /// Fecha programada en formato `YYYY-MM-DD`.
  final String fechaCobro;
  final double montoAEsperar;

  const TurnoCalendario({
    required this.turno,
    required this.vuelta,
    required this.numero,
    required this.fechaCobro,
    required this.montoAEsperar,
    this.esNumeroMuerto = false,
    this.idUser,
    this.nombreUsuario,
  });

  DateTime? get fechaDate {
    final partes = fechaCobro.split('T').first.split('-');
    if (partes.length != 3) return null;
    final y = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    final d = int.tryParse(partes[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime.utc(y, m, d);
  }

  @override
  List<Object?> get props => [
        turno,
        vuelta,
        numero,
        esNumeroMuerto,
        idUser,
        nombreUsuario,
        fechaCobro,
        montoAEsperar,
      ];
}

/// Calendario completo de turnos de una tanda (AP-06).
class CalendarioTanda extends Equatable {
  final String idTanda;
  final String fechaInicioPagos;
  final List<TurnoCalendario> turnos;

  const CalendarioTanda({
    required this.idTanda,
    required this.fechaInicioPagos,
    required this.turnos,
  });

  /// Turnos que corresponden a un día específico (comparando año, mes y día).
  List<TurnoCalendario> turnosEnDia(DateTime dia) {
    final clave = _formatearIso(dia);
    return turnos
        .where((t) => t.fechaCobro.split('T').first == clave)
        .toList();
  }

  /// Construye el calendario de turnos localmente a partir de [TandaEntity]
  /// siguiendo las mismas reglas de dominio del backend (`generarCalendario`).
  factory CalendarioTanda.desdeTanda(TandaEntity tanda) {
    final inicioBase = _parsearFecha(tanda.startDate) ?? DateTime.utc(2026, 1, 1);
    final tieneMuerto = tanda.hasDeadNumber == true;
    final periodicidad = tanda.periodo.toLowerCase().trim();
    final totalParticipantes = tanda.totalParticipantes > 0 ? tanda.totalParticipantes : 1;
    final montoTurno = double.parse((tanda.monto * totalParticipantes).toStringAsFixed(2));

    final porNumero = {
      for (final n in tanda.numeros.where((n) => n.roundNumber == 1)) n.numberValue: n,
    };

    final orden = <int>[
      if (tieneMuerto) 0,
      for (var i = 1; i <= totalParticipantes; i++) i,
    ];

    final turnos = <TurnoCalendario>[];
    for (var i = 0; i < orden.length; i++) {
      final numero = orden[i];
      final esMuerto = numero == 0;
      final fecha = _sumarPeriodos(inicioBase, periodicidad, i);
      final registro = porNumero[numero];
      turnos.add(
        TurnoCalendario(
          turno: i + 1,
          vuelta: 1,
          numero: numero,
          esNumeroMuerto: esMuerto,
          nombreUsuario: esMuerto ? 'Número muerto (caja)' : registro?.userName,
          fechaCobro: _formatearIso(fecha),
          montoAEsperar: esMuerto ? 0 : montoTurno,
        ),
      );
    }

    final inicioPagos = _sumarPeriodos(inicioBase, periodicidad, tieneMuerto ? 1 : 0);

    return CalendarioTanda(
      idTanda: tanda.id,
      fechaInicioPagos: _formatearIso(inicioPagos),
      turnos: turnos,
    );
  }

  static DateTime? _parsearFecha(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final limpio = raw.split('T').first;
    final partes = limpio.split('-');
    if (partes.length != 3) return null;
    final y = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    final d = int.tryParse(partes[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime.utc(y, m, d);
  }

  static DateTime _sumarPeriodos(DateTime fecha, String periodicidad, int periodos) {
    if (periodos <= 0) return fecha;
    switch (periodicidad) {
      case 'diaria':
      case 'diario':
        return fecha.add(Duration(days: periodos));
      case 'semanal':
        return fecha.add(Duration(days: periodos * 7));
      case 'mensual':
        final totalMeses = (fecha.month - 1) + periodos;
        final anio = fecha.year + (totalMeses ~/ 12);
        final mes = (totalMeses % 12) + 1;
        final ultimoDiaMes = DateTime.utc(anio, mes + 1, 0).day;
        final dia = fecha.day <= ultimoDiaMes ? fecha.day : ultimoDiaMes;
        return DateTime.utc(anio, mes, dia);
      case 'quincenal':
      default:
        return fecha.add(Duration(days: periodos * 15));
    }
  }

  static String _formatearIso(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  List<Object?> get props => [idTanda, fechaInicioPagos, turnos];
}

