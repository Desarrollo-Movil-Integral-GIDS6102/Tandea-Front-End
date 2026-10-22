import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/utils/formato_moneda.dart';

/// Encabezado de "Registrar pago": tanda, turno/vuelta y monto esperado en grande.
class ResumenMontoCard extends StatelessWidget {
  final String nombreTanda;
  final int? numeroTurno;
  final int? vuelta;
  final double cuota;

  const ResumenMontoCard({
    super.key,
    required this.nombreTanda,
    required this.cuota,
    this.numeroTurno,
    this.vuelta,
  });

  @override
  Widget build(BuildContext context) {
    final detalles = [
      if (numeroTurno != null) 'Turno #$numeroTurno',
      if (vuelta != null) 'Vuelta $vuelta',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombreTanda,
            style: const TextStyle(
              color: AppColors.primaryVariant,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (detalles.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detalles,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Monto a pagar',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            formatearMonedaMxn(cuota),
            key: const Key('monto_esperado'),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'MXN',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
