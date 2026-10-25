import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campos "Monto por transferencia" y "Monto en efectivo" del pago híbrido.
class CamposMontoHibrido extends StatelessWidget {
  final TextEditingController transferenciaController;
  final TextEditingController efectivoController;
  final ValueChanged<String> onTransferenciaChanged;
  final ValueChanged<String> onEfectivoChanged;
  final bool habilitado;

  /// Aviso bajo los campos cuando la suma no coincide con la cuota (null = sin aviso).
  final String? mensajeSuma;

  const CamposMontoHibrido({
    super.key,
    required this.transferenciaController,
    required this.efectivoController,
    required this.onTransferenciaChanged,
    required this.onEfectivoChanged,
    this.habilitado = true,
    this.mensajeSuma,
  });

  /// Solo dígitos con un punto decimal y máximo 2 decimales.
  static final List<TextInputFormatter> _formatosMonto = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('campo_monto_transferencia'),
          controller: transferenciaController,
          enabled: habilitado,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _formatosMonto,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Monto por transferencia',
            prefixText: r'$ ',
            hintText: '0.00',
          ),
          onChanged: onTransferenciaChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('campo_monto_efectivo'),
          controller: efectivoController,
          enabled: habilitado,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _formatosMonto,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Monto en efectivo',
            prefixText: r'$ ',
            hintText: '0.00',
            errorText: mensajeSuma,
          ),
          onChanged: onEfectivoChanged,
        ),
      ],
    );
  }
}
