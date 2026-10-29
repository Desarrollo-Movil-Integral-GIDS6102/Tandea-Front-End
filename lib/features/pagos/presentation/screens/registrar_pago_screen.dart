import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/pagos/presentation/widgets/campos_monto_hibrido.dart';
import 'package:tandea/features/pagos/presentation/widgets/comprobante_selector.dart';
import 'package:tandea/features/pagos/presentation/widgets/resumen_monto_card.dart';
import 'package:tandea/features/pagos/presentation/widgets/selector_metodo_pago.dart';

/// Datos que recibe la pantalla al navegar a [RouteNames.registrarPago] por `extra`.
class RegistrarPagoArgs {
  final String nombreTanda;

  /// `id_number` del turno del usuario (lo que espera el backend).
  final int idNumber;

  /// Número visible del turno (`number_value`).
  final int? numeroTurno;
  final int? vuelta;

  /// Cuota de la tanda (monto esperado).
  final double cuota;

  const RegistrarPagoArgs({
    required this.nombreTanda,
    required this.idNumber,
    required this.cuota,
    this.numeroTurno,
    this.vuelta,
  });
}

/// Pantalla para que el participante registre su pago (AP-03).
class RegistrarPagoScreen extends StatefulWidget {
  final RegistrarPagoArgs args;

  const RegistrarPagoScreen({super.key, required this.args});

  @override
  State<RegistrarPagoScreen> createState() => _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends State<RegistrarPagoScreen> {
  final _transferenciaController = TextEditingController();
  final _efectivoController = TextEditingController();
  late final _montoController =
      TextEditingController(text: widget.args.cuota.toStringAsFixed(2));

  @override
  void dispose() {
    _transferenciaController.dispose();
    _efectivoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _registrarPago() async {
    final registrado = await context.read<PagoProvider>().registrarPago(
      idNumber: widget.args.idNumber,
      cuota: widget.args.cuota,
    );

    if (!mounted || !registrado) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('dialogo_pago_enviado'),
        icon: const Icon(Icons.hourglass_top_rounded, color: AppColors.success, size: 40),
        title: const Text('Pago enviado'),
        content: const Text(
          'Tu pago quedó registrado y está esperando la confirmación del organizador.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );

    // "Entendido" regresa a la pantalla anterior (el provider ya notificó el pago nuevo)
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PagoProvider>();
    final args = widget.args;
    final metodo = provider.metodoPago;
    final enviando = provider.enviando;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResumenMontoCard(
                nombreTanda: args.nombreTanda,
                numeroTurno: args.numeroTurno,
                vuelta: args.vuelta,
                cuota: args.cuota,
              ),
              const SizedBox(height: 24),
              const Text(
                '¿Cómo pagaste?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectorMetodoPago(
                seleccionado: metodo,
                habilitado: !enviando,
                onChanged: provider.seleccionarMetodo,
              ),
              const SizedBox(height: 20),
              if (metodo.esHibrido)
                CamposMontoHibrido(
                  transferenciaController: _transferenciaController,
                  efectivoController: _efectivoController,
                  habilitado: !enviando,
                  onTransferenciaChanged: provider.actualizarMontoTransferencia,
                  onEfectivoChanged: provider.actualizarMontoEfectivo,
                  // Avisa solo cuando ya escribió algo y la suma no cuadra
                  mensajeSuma: provider.sumaValida(args.cuota) ||
                          (provider.montoTransferencia == null && provider.montoEfectivo == null)
                      ? null
                      : 'Los dos montos deben sumar ${formatearMonedaMxn(args.cuota)}',
                )
              else
                _MontoUnico(
                  metodo: metodo,
                  controller: _montoController,
                  habilitado: !enviando,
                  onChanged: provider.actualizarMontoUnico,
                ),
              const SizedBox(height: 16),
              ComprobanteSelector(
                requerido: metodo.requiereComprobante,
                habilitado: !enviando,
                comprobante: provider.comprobante,
                onComprobanteSeleccionado: provider.seleccionarComprobante,
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 16),
                _BannerError(
                  mensaje: provider.errorMessage!,
                  onCerrar: provider.clearError,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                key: const Key('boton_ya_pague'),
                text: 'Ya pagué',
                isLoading: enviando,
                onPressed: provider.puedeEnviar(args.cuota) ? _registrarPago : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Monto para transferencia o efectivo; empieza con la cuota y se puede editar.
class _MontoUnico extends StatelessWidget {
  final MetodoPago metodo;
  final TextEditingController controller;
  final bool habilitado;
  final ValueChanged<String> onChanged;

  const _MontoUnico({
    required this.metodo,
    required this.controller,
    required this.habilitado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('campo_monto_unico'),
      controller: controller,
      enabled: habilitado,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      decoration: InputDecoration(
        labelText:
            metodo == MetodoPago.efectivo ? 'Monto en efectivo' : 'Monto por transferencia',
        prefixText: r'$ ',
      ),
      onChanged: onChanged,
    );
  }
}

class _BannerError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onCerrar;

  const _BannerError({required this.mensaje, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('banner_error_pago'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            onPressed: onCerrar,
          ),
        ],
      ),
    );
  }
}
