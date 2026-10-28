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
      selector: (_, provider) => index < provider.cantidadFiltrados ? provider.participanteEn(index) : null,
      builder: (context, participante, _) {
        if (participante == null) {
          return const SizedBox.shrink();
        }
        return _FilaParticipante(participante: participante);
      },
    );
  }
}

class _FilaParticipante extends StatelessWidget {
  final ParticipanteSeguimiento participante;

  const _FilaParticipante({required this.participante});

  String get _detalle {
    if (participante.isDeadNumber) {
      return 'Número muerto';
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
    return participante.montoPagado > 0 ? 'Pago por confirmar' : 'Sin pago registrado';
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
    final color = colorEstadoPago(participante.estadoPago);
    final idPayment = participante.idPayment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          key: Key('fila_seguimiento_${participante.idNumber}'),
          borderRadius: BorderRadius.circular(14),
          onTap: idPayment == null ? null : () => _revisarPago(context, idPayment),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: _contenido(color, idPayment != null),
          ),
        ),
      ),
    );
  }

  Widget _contenido(Color color, bool revisable) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            '${participante.numeroTurno}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participante.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(_detalle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ChipEstadoPago(estado: participante.estadoPago),
        if (revisable) const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
      ],
    );
  }
}

Color colorEstadoPago(EstadoPagoSeguimiento estado) => switch (estado) {
  EstadoPagoSeguimiento.pagado => AppColors.success,
  EstadoPagoSeguimiento.pendiente => AppColors.warning,
  EstadoPagoSeguimiento.atrasado => AppColors.error,
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            estado.etiqueta,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
