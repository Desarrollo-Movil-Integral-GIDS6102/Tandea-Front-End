import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/pagos/presentation/screens/registrar_pago_screen.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

/// Tarjeta optimizada de tanda para `ListView.builder`.
///
/// Presenta chips de estado de la tanda, métricas financieras y el indicador
/// de pago "Al día" / "Pendiente" con retroalimentación visual clara.
class TandaCardItem extends StatelessWidget {
  final TandaEntity tanda;
  final String rol;
  final VoidCallback? onTap;

  const TandaCardItem({
    super.key,
    required this.tanda,
    this.rol = 'participante',
    this.onTap,
  });

  bool get isOrganizador => rol == 'organizador' || rol == 'dueno';

  void _navegarAccion(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    // El pago se hace desde el detalle, con el id_number real de cada número
    context.push(RouteNames.tandaDetalle(tanda.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAlDia = tanda.indicadorPago.esAlDia;

    return Card(
      key: Key('tanda_card_${tanda.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isAlDia
              ? Colors.grey.shade200
              : Colors.orange.shade200,
          width: isAlDia ? 1.0 : 1.5,
        ),
      ),
      color: AppColors.surfaceLight,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navegarAccion(context),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado: Icono, Nombre y Chip de Estado de la Tanda
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOrganizador
                            ? [AppColors.secondary, AppColors.primary]
                            : [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isOrganizador
                          ? Icons.admin_panel_settings_rounded
                          : Icons.savings_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tanda.nombre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (tanda.inviteCode != null && tanda.inviteCode!.isNotEmpty) ...[
                              Text(
                                tanda.inviteCode!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(' • ', style: TextStyle(color: Colors.grey)),
                            ],
                            Text(
                              tanda.periodo.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chip de estado de la tanda (ACTIVA, PENDIENTE, FINALIZADA)
                  _buildEstadoTandaChip(tanda.estado),
                ],
              ),
              const SizedBox(height: 16),

              // Contenedor de Métricas Financieras
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricaItem(
                      'Cuota',
                      '\$${tanda.monto.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                    _buildMetricaItem(
                      'Participantes',
                      '${tanda.totalParticipantes}',
                    ),
                    _buildMetricaItem(
                      'Total Tanda',
                      '\$${(tanda.monto * tanda.totalParticipantes).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Pie de la Tarjeta: Indicador de Pago (Al día / Pendiente) y Acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Chip de Indicador de Pago (calculado por el backend)
                  _buildIndicadorPagoChip(tanda.indicadorPago, tanda.id),

                  // Botón de acción según el rol
                  if (isOrganizador)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('btn_seguimiento_${tanda.id}'),
                          tooltip: 'Seguimiento de pagos',
                          onPressed: () {
                            context.push(RouteNames.seguimientoTandaDe(tanda.id), extra: tanda);
                          },
                          icon: const Icon(Icons.fact_check_outlined, size: 20),
                          color: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        OutlinedButton.icon(
                          key: Key('btn_compartir_${tanda.id}'),
                          onPressed: () {
                            context.push(RouteNames.compartirCodigo, extra: tanda);
                          },
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Compartir', style: TextStyle(fontSize: 12.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    )
                  // Los pagos se habilitan cuando el organizador inicia la tanda
                  else if (tanda.idNumberUsuario != null && tanda.esActiva)
                    // Acceso mínimo a "Registrar pago" mientras llega el detalle de la tanda (SP-3)
                    FilledButton.icon(
                      key: Key('btn_pagar_${tanda.id}'),
                      onPressed: () {
                        context.push(
                          RouteNames.registrarPago,
                          extra: RegistrarPagoArgs(
                            nombreTanda: tanda.nombre,
                            idNumber: tanda.idNumberUsuario!,
                            numeroTurno: tanda.numeroTurnoUsuario,
                            vuelta: 1,
                            cuota: tanda.monto,
                          ),
                        );
                      },
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Pagar', style: TextStyle(fontSize: 12.5)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else
                    TextButton.icon(
                      key: Key('btn_detalle_${tanda.id}'),
                      onPressed: () => _navegarAccion(context),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Ver detalle', style: TextStyle(fontSize: 12.5)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricaItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primary : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoTandaChip(String estado) {
    final normalizado = estado.toUpperCase();
    final Color bgColor;
    final Color textColor;

    switch (normalizado) {
      case 'ACTIVA':
        bgColor = const Color(0xFFE0F2F1); // Teal claro
        textColor = const Color(0xFF00695C);
        break;
      case 'PENDIENTE':
        bgColor = const Color(0xFFFFF8E1); // Amber claro
        textColor = const Color(0xFFF57F17);
        break;
      case 'FINALIZADA':
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF455A64);
        break;
      case 'CANCELADA':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = AppColors.textSecondaryLight;
    }

    return Container(
      key: Key('chip_estado_${tanda.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        normalizado,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildIndicadorPagoChip(IndicadorPago indicador, String idTanda) {
    final bool esAlDia = indicador.esAlDia;
    final keyName = esAlDia ? 'badge_pago_al_dia_$idTanda' : 'badge_pago_pendiente_$idTanda';

    final Color bgColor = esAlDia ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final Color borderColor = esAlDia ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80);
    final Color contentColor = esAlDia ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final IconData icon = esAlDia ? Icons.check_circle_rounded : Icons.schedule_rounded;
    final String label = esAlDia ? 'Al día' : 'Pendiente';

    return Container(
      key: Key(keyName),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: contentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}
