import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/entregas/presentation/providers/entrega_provider.dart';
import 'package:tandea/features/pagos/presentation/widgets/campos_monto_hibrido.dart';
import 'package:tandea/features/pagos/presentation/widgets/comprobante_selector.dart';

/// Datos del turno vigente que recibe [RegistrarEntregaScreen] por `extra`.
class RegistrarEntregaArgs {
  final int idNumber;
  final int numero;
  final String nombreReceptor;

  /// Lo que se entrega: el total del turno menos las cuotas no confirmadas (AP-10).
  final double total;

  /// Total del turno si todos hubieran pagado; si es mayor que [total] se muestra el descuento.
  final double? totalTurno;
  final int cuotasNoConfirmadas;

  /// Por qué la entrega no se puede registrar todavía; null si sí se puede.
  final String? motivoBloqueo;

  const RegistrarEntregaArgs({
    required this.idNumber,
    required this.numero,
    required this.nombreReceptor,
    required this.total,
    this.totalTurno,
    this.cuotasNoConfirmadas = 0,
    this.motivoBloqueo,
  });

  /// Descuento por cuotas no confirmadas; 0 si no hay.
  double get descuento => (totalTurno ?? total) > total ? (totalTurno ?? total) - total : 0;
}

/// El organizador registra la entrega del dinero del turno con foto de evidencia.
class RegistrarEntregaScreen extends StatefulWidget {
  final RegistrarEntregaArgs args;

  const RegistrarEntregaScreen({super.key, required this.args});

  @override
  State<RegistrarEntregaScreen> createState() => _RegistrarEntregaScreenState();
}

class _RegistrarEntregaScreenState extends State<RegistrarEntregaScreen> {
  late final _transferencia = TextEditingController(text: widget.args.total.toStringAsFixed(2));
  final _efectivo = TextEditingController();

  @override
  void dispose() {
    _transferencia.dispose();
    _efectivo.dispose();
    super.dispose();
  }

  double get _montoTransferencia => parsearMonto(_transferencia.text) ?? 0;
  double get _montoEfectivo => parsearMonto(_efectivo.text) ?? 0;

  bool get _sumaValida =>
      montoACentavos(_montoTransferencia) + montoACentavos(_montoEfectivo) ==
      montoACentavos(widget.args.total);

  Future<void> _registrar() async {
    final ok = await context.read<EntregaProvider>().registrar(
          idNumber: widget.args.idNumber,
          transferencia: _montoTransferencia,
          efectivo: _montoEfectivo,
        );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Entrega registrada. Falta que el participante la confirme.'),
      backgroundColor: AppColors.success,
    ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EntregaProvider>();
    final args = widget.args;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar entrega')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Turno #${args.numero} · ${args.nombreReceptor}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Monto a entregar: ${formatearMonedaMxn(args.total)}',
              key: const Key('entrega_total'),
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
            if (args.descuento > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Total del turno ${formatearMonedaMxn(args.totalTurno!)} − '
                '${args.cuotasNoConfirmadas} ${args.cuotasNoConfirmadas == 1 ? 'cuota no confirmada' : 'cuotas no confirmadas'} '
                '(${formatearMonedaMxn(args.descuento)})',
                key: const Key('entrega_descuento'),
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
              ),
            ],
            if (args.motivoBloqueo != null) ...[
              const SizedBox(height: 12),
              Text(
                args.motivoBloqueo!,
                key: const Key('entrega_bloqueada'),
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 20),
            CamposMontoHibrido(
              transferenciaController: _transferencia,
              efectivoController: _efectivo,
              habilitado: !provider.enviando,
              onTransferenciaChanged: (_) => setState(() {}),
              onEfectivoChanged: (_) => setState(() {}),
              mensajeSuma: _sumaValida
                  ? null
                  : 'Los dos montos deben sumar ${formatearMonedaMxn(args.total)}',
            ),
            const SizedBox(height: 16),
            ComprobanteSelector(
              requerido: true,
              habilitado: !provider.enviando,
              comprobante: provider.evidencia,
              onComprobanteSeleccionado: provider.seleccionarEvidencia,
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                key: const Key('entrega_error'),
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('btn_registrar_entrega'),
              text: 'Registrar entrega',
              isLoading: provider.enviando,
              onPressed: _sumaValida && provider.evidencia != null && args.motivoBloqueo == null
                  ? _registrar
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
