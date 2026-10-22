import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/pagos/presentation/widgets/campos_monto_hibrido.dart';
import 'package:tandea/features/pagos/presentation/widgets/comprobante_placeholder.dart';
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

  @override
  void dispose() {
    _transferenciaController.dispose();
    _efectivoController.dispose();
    super.dispose();
  }

  Future<void> _registrarPago() async {
    final provider = context.read<PagoProvider>();
    final registrado = await provider.registrarPago(
      idNumber: widget.args.idNumber,
      cuota: widget.args.cuota,
    );

    if (!mounted || !registrado) {
      return;
    }

    // TODO: SP-2-[FE-PAGO] Mostrar pantalla/diálogo "Pago enviado, esperando confirmación".
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago registrado. Queda pendiente de confirmación del organizador.'),
        backgroundColor: AppColors.success,
      ),
    );
    if (context.canPop()) {
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
                )
              else
                _MontoFijo(metodo: metodo, cuota: args.cuota),
              const SizedBox(height: 16),
              ComprobantePlaceholder(
                requerido: metodo.requiereComprobante,
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
                onPressed: provider.sumaValida ? _registrarPago : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Monto (igual a la cuota) para transferencia o efectivo.
class _MontoFijo extends StatelessWidget {
  final MetodoPago metodo;
  final double cuota;

  const _MontoFijo({required this.metodo, required this.cuota});

  @override
  Widget build(BuildContext context) {
    final etiqueta =
        metodo == MetodoPago.efectivo ? 'Monto en efectivo' : 'Monto por transferencia';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            formatearMonedaMxn(cuota),
            key: const Key('monto_fijo'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
