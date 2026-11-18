import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/pagos/presentation/screens/revisar_pago_screen.dart';
import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';
import 'package:tandea/features/tandas/presentation/providers/seguimiento_tanda_provider.dart';

/// Fila del panel de seguimiento. Escucha solo al participante de su posición
/// en la lista filtrada, así que no se reconstruye si cambia otra fila.
class ParticipanteSeguimientoItem extends StatelessWidget {
  final int index;

  const ParticipanteSeguimientoItem({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Selector<SeguimientoTandaProvider, ParticipanteSeguimiento?>(
      // Al pasar a una pestaña con menos filas, las sobrantes pueden reconstruirse
      // antes de que la lista las descarte.
      selector: (_, provider) => index < provider.cantidadFiltrados
          ? provider.participanteEn(index)
          : null,
      builder: (context, participante, _) {
        if (participante == null) {
          return const SizedBox.shrink();
        }
        return _FilaParticipante(participante: participante);
      },
    );
  }
}

/// Fila especial con tarjeta verde para el "Número Muerto" en el panel de seguimiento (AP-10).
class TarjetaNumeroMuertoSeguimiento extends StatelessWidget {
  final NumeroMuertoSeguimiento numeroMuerto;
  final Key? cardKey;

  const TarjetaNumeroMuertoSeguimiento({
    super.key,
    required this.numeroMuerto,
    this.cardKey,
  });

  String get _detalle {
    if (numeroMuerto.pagosCubiertos > 0) {
      final etiquetaPagos = numeroMuerto.pagosCubiertos == 1 ? 'pago' : 'pagos';
      return 'Cubrió ${numeroMuerto.pagosCubiertos} $etiquetaPagos · ${formatearMonedaMxn(numeroMuerto.montoCubierto)}';
    }
    return 'Fondo de respaldo · Se cobra al final de la vuelta';
  }

  @override
  Widget build(BuildContext context) {
    const colorVerde = AppColors.success;
    const fondoVerde = Color(0xFFECFDF5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        key: cardKey ?? const Key('fila_numero_muerto_seguimiento'),
        color: fondoVerde,
        elevation: 1.5,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorVerde.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: colorVerde, width: 5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorVerde.withValues(alpha: 0.16),
                child: Text(
                  '#${numeroMuerto.numeroTurno}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: colorVerde,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 16, color: colorVerde),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Número Muerto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colorVerde,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _detalle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ChipEstadoTurno(
                key: Key('chip_estado_turno_${numeroMuerto.idNumber}'),
                estado: numeroMuerto.estadoTurnoChip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaParticipante extends StatelessWidget {
  final ParticipanteSeguimiento participante;

  const _FilaParticipante({required this.participante});

  String get _detalle {
    if (participante.isDeadNumber) {
      return 'Número Muerto · Fondo de respaldo';
    }
    if (participante.cubiertoPorNumeroMuerto) {
      return participante.montoPagado > 0
          ? 'Cubierto por número muerto · ${formatearMonedaMxn(participante.montoPagado)}'
          : 'Cubierto por número muerto';
    }
    if (participante.estadoPago == EstadoPagoSeguimiento.pagado) {
      final monto = participante.montoPagado > 0
          ? 'Pagó ${formatearMonedaMxn(participante.montoPagado)}'
          : 'Pago confirmado';
      final fecha = participante.fechaPago;
      return fecha == null
          ? monto
          : '$monto · ${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';
    }
    if (participante.estadoPago == EstadoPagoSeguimiento.atrasado) {
      return 'Plazo vencido sin pago';
    }
    return participante.montoPagado > 0
        ? 'Pago por confirmar'
        : 'Sin pago registrado';
  }

  /// Abre "Revisar pago" y, al volver, refresca el panel por si se confirmó o rechazó.
  Future<void> _revisarPago(BuildContext context, int idPayment) async {
    final provider = context.read<SeguimientoTandaProvider>();
    await context.push(
      RouteNames.revisarPagoDe(idPayment),
      extra: RevisarPagoArgs(
        idPayment: idPayment,
        nombreParticipante: participante.nombre,
        numeroTurno: participante.numeroTurno,
        cuota: provider.seguimiento?.cuota,
      ),
    );
    await provider.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final esMuerto = participante.isDeadNumber;
    final color = esMuerto
        ? AppColors.success
        : colorEstadoPago(participante.estadoPago);
    final colorFondo = esMuerto ? const Color(0xFFECFDF5) : AppColors.surface;
    final colorBorde = esMuerto
        ? AppColors.success.withValues(alpha: 0.45)
        : AppColors.border;
    final idPayment = participante.idPayment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: colorFondo,
        elevation: 1.5,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorBorde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('fila_seguimiento_${participante.idNumber}'),
          onTap: idPayment == null
              ? null
              : () => _revisarPago(context, idPayment),
          // La franja de color de la izquierda deja ver el estado de un vistazo.
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: _contenido(color, idPayment != null, esMuerto),
          ),
        ),
      ),
    );
  }

  Widget _contenido(Color color, bool revisable, bool esMuerto) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(
            '#${participante.numeroTurno}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (esMuerto) ...[
                    const Icon(
                      Icons.shield_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      esMuerto ? 'Número Muerto' : participante.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: esMuerto
                            ? AppColors.success
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                _detalle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!esMuerto) ...[
              ChipEstadoPago(estado: participante.estadoPago),
              const SizedBox(height: 4),
            ],
            ChipEstadoTurno(
              key: Key('chip_estado_turno_${participante.idNumber}'),
              estado: participante.estadoTurnoChip,
            ),
            if (revisable) ...[
              const SizedBox(height: 4),
              const Text(
                'Ver pago ›',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

Color colorEstadoPago(EstadoPagoSeguimiento estado) => switch (estado) {
  EstadoPagoSeguimiento.pagado => AppColors.success,
  EstadoPagoSeguimiento.pendiente => AppColors.warning,
  EstadoPagoSeguimiento.atrasado => AppColors.error,
};

Color colorEstadoTurno(EstadoTurnoSeguimiento estado) => switch (estado) {
  EstadoTurnoSeguimiento.alDia => AppColors.success,
  EstadoTurnoSeguimiento.enRiesgo => AppColors.error,
  EstadoTurnoSeguimiento.cubierto => AppColors.primary,
};

class ChipEstadoPago extends StatelessWidget {
  final EstadoPagoSeguimiento estado;

  const ChipEstadoPago({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoPago(estado);
    final icono = switch (estado) {
      EstadoPagoSeguimiento.pagado => Icons.check_circle_rounded,
      EstadoPagoSeguimiento.pendiente => Icons.schedule_rounded,
      EstadoPagoSeguimiento.atrasado => Icons.error_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            estado.etiqueta,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip que muestra el estado del turno: `Al día`, `En riesgo` o `Cubierto` (AP-10).
class ChipEstadoTurno extends StatelessWidget {
  final EstadoTurnoSeguimiento estado;

  const ChipEstadoTurno({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoTurno(estado);
    final icono = switch (estado) {
      EstadoTurnoSeguimiento.alDia => Icons.verified_rounded,
      EstadoTurnoSeguimiento.enRiesgo => Icons.warning_amber_rounded,
      EstadoTurnoSeguimiento.cubierto => Icons.shield_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            estado.etiqueta,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
