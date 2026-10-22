import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';

/// Selector del método de pago: Transferencia, Efectivo o Híbrido.
class SelectorMetodoPago extends StatelessWidget {
  final MetodoPago seleccionado;
  final ValueChanged<MetodoPago> onChanged;
  final bool habilitado;

  const SelectorMetodoPago({
    super.key,
    required this.seleccionado,
    required this.onChanged,
    this.habilitado = true,
  });

  static String _descripcion(MetodoPago metodo) {
    return switch (metodo) {
      MetodoPago.transferencia => 'Pagaste todo por transferencia bancaria',
      MetodoPago.efectivo => 'Entregaste todo en efectivo al organizador',
      MetodoPago.hibrido => 'Una parte por transferencia y otra en efectivo',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: RadioGroup<MetodoPago>(
        groupValue: seleccionado,
        onChanged: (metodo) {
          if (habilitado && metodo != null) {
            onChanged(metodo);
          }
        },
        child: Column(
          children: [
            for (final metodo in MetodoPago.values)
              RadioListTile<MetodoPago>(
                key: Key('metodo_${metodo.valor}'),
                value: metodo,
                enabled: habilitado,
                activeColor: AppColors.primary,
                title: Text(metodo.etiqueta),
                subtitle: Text(_descripcion(metodo)),
              ),
          ],
        ),
      ),
    );
  }
}
