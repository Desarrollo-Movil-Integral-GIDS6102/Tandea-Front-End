import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/entities/resultado_ocr.dart';
import 'package:tandea/features/pagos/presentation/providers/revisar_pago_provider.dart';

/// Datos que recibe la pantalla al navegar a [RouteNames.revisarPago] por `extra`.
class RevisarPagoArgs {
  final int idPayment;

  /// Si ya se tiene el pago (p. ej. desde una lista), se muestra mientras se refresca.
  final PagoEntity? pago;
  final String? nombreParticipante;
  final int? numeroTurno;

  /// Cuota de la tanda, para mostrarla junto al total pagado.
  final double? cuota;

  const RevisarPagoArgs({required this.idPayment, this.pago, this.nombreParticipante, this.numeroTurno, this.cuota});
}

/// Pantalla "Revisar pago" (AP-05): el organizador ve el comprobante con zoom,
/// compara el monto que leyó el OCR contra el esperado y confirma o rechaza.
class RevisarPagoScreen extends StatefulWidget {
  final RevisarPagoArgs args;

  const RevisarPagoScreen({super.key, required this.args});

  @override
  State<RevisarPagoScreen> createState() => _RevisarPagoScreenState();
}

class _RevisarPagoScreenState extends State<RevisarPagoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RevisarPagoProvider>().cargar(widget.args.idPayment);
      }
    });
  }

  Future<void> _confirmar() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<RevisarPagoProvider>().confirmar();
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Pago confirmado')));
    }
  }

  Future<void> _rechazar() async {
    final provider = context.read<RevisarPagoProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final motivo = await showDialog<String>(context: context, builder: (_) => const _DialogoRechazo());
    if (motivo == null) {
      return;
    }
    final ok = await provider.rechazar(motivo);
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Pago rechazado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RevisarPagoProvider>();
    final pago = provider.pago;
    final args = widget.args;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Revisar pago')),
      body: pago == null
          ? (provider.cargaFallida
                ? _ErrorCarga(
                    mensaje: provider.errorMessage ?? 'No pudimos cargar el pago.',
                    onReintentar: () => provider.cargar(args.idPayment),
                  )
                : const Center(child: CircularProgressIndicator(color: AppColors.primary)))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => provider.cargar(args.idPayment),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _Encabezado(pago: pago, nombre: args.nombreParticipante, numeroTurno: args.numeroTurno),
                  const SizedBox(height: 16),
                  _VisorComprobante(pago: pago),
                  const SizedBox(height: 16),
                  _ComparacionOcr(pago: pago),
                  const SizedBox(height: 16),
                  _Desglose(pago: pago, cuota: args.cuota),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _BannerError(mensaje: provider.errorMessage!, onCerrar: provider.clearError),
                  ],
                  const SizedBox(height: 24),
                  if (pago.puedeRevisarse)
                    _BotonesRevision(
                      habilitado: provider.puedeRevisar,
                      accion: provider.accion,
                      onConfirmar: _confirmar,
                      onRechazar: _rechazar,
                    )
                  else
                    _ResultadoRevision(pago: pago),
                ],
              ),
            ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final PagoEntity pago;
  final String? nombre;
  final int? numeroTurno;

  const _Encabezado({required this.pago, this.nombre, this.numeroTurno});

  @override
  Widget build(BuildContext context) {
    final titulo = nombre ?? 'Pago #${pago.idPayment}';
    final subtitulo = [if (numeroTurno != null) 'Turno $numeroTurno', pago.metodoPago.etiqueta].join(' · ');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(subtitulo, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        _ChipEstadoPago(pago: pago),
      ],
    );
  }
}

class _ChipEstadoPago extends StatelessWidget {
  final PagoEntity pago;

  const _ChipEstadoPago({required this.pago});

  @override
  Widget build(BuildContext context) {
    final (color, texto) = pago.estaConfirmado
        ? (AppColors.success, 'Confirmado')
        : pago.estaRechazado
        ? (AppColors.error, 'Rechazado')
        : (AppColors.warning, 'Pendiente');

    return _Chip(key: const Key('chip_estado_pago'), color: color, texto: texto);
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final String texto;
  final IconData? icono;

  const _Chip({super.key, required this.color, required this.texto, this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: 14, color: color), const SizedBox(width: 4)],
          Text(
            texto,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

/// Comprobante con zoom (pellizcar o doble toque para ampliar en pantalla completa).
class _VisorComprobante extends StatelessWidget {
  final PagoEntity pago;

  const _VisorComprobante({required this.pago});

  void _abrirPantallaCompleta(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Comprobante'),
          ),
          body: Center(
            child: InteractiveViewer(
              key: const Key('visor_comprobante_completo'),
              minScale: 1,
              maxScale: 6,
              child: _ImagenComprobante(url: url),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = pago.evidenceUrl;

    if (url == null || url.isEmpty) {
      final efectivo = pago.transferAmount <= 0;
      return _Tarjeta(
        child: Row(
          children: [
            Icon(
              efectivo ? Icons.payments_outlined : Icons.image_not_supported_outlined,
              color: AppColors.textDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                efectivo ? 'Pago en efectivo: no requiere comprobante.' : 'El participante no adjuntó comprobante.',
                key: const Key('sin_comprobante'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return _Tarjeta(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comprobante',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  key: const Key('btn_comprobante_pantalla_completa'),
                  tooltip: 'Ver en pantalla completa',
                  icon: const Icon(Icons.fullscreen_rounded),
                  onPressed: () => _abrirPantallaCompleta(context, url),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Container(
              height: 320,
              color: const Color(0xFFF3F4F6),
              child: InteractiveViewer(
                key: const Key('visor_comprobante'),
                minScale: 1,
                maxScale: 5,
                child: Center(child: _ImagenComprobante(url: url)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Pellizca la imagen para hacer zoom',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenComprobante extends StatelessWidget {
  final String url;

  const _ImagenComprobante({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progreso) =>
          progreso == null ? child : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textDisabled),
            SizedBox(height: 8),
            Text('No se pudo cargar el comprobante', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Monto detectado por el OCR contra el esperado (la parte por transferencia).
class _ComparacionOcr extends StatelessWidget {
  final PagoEntity pago;

  const _ComparacionOcr({required this.pago});

  @override
  Widget build(BuildContext context) {
    final resultado = ResultadoOcr.de(pago);
    if (resultado == ResultadoOcr.noAplica) {
      return const SizedBox.shrink();
    }

    final (color, icono) = switch (resultado) {
      ResultadoOcr.coincide => (AppColors.success, Icons.check_circle_rounded),
      ResultadoOcr.noCoincide => (AppColors.error, Icons.warning_amber_rounded),
      _ => (AppColors.textSecondary, Icons.help_outline_rounded),
    };
    final detectado = pago.ocrDetectedAmount;

    return _Tarjeta(
      key: const Key('comparacion_ocr'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lectura automática (OCR)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              _Chip(key: const Key('chip_resultado_ocr'), color: color, texto: resultado.etiqueta, icono: icono),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MontoEtiquetado(
                  key: const Key('monto_detectado'),
                  etiqueta: 'Detectado',
                  valor: detectado == null ? '—' : formatearMonedaMxn(detectado),
                  color: resultado == ResultadoOcr.noCoincide ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              const Icon(Icons.compare_arrows_rounded, color: AppColors.textDisabled),
              Expanded(
                child: _MontoEtiquetado(
                  key: const Key('monto_esperado'),
                  etiqueta: 'Esperado',
                  valor: formatearMonedaMxn(pago.transferAmount),
                  alinearDerecha: true,
                ),
              ),
            ],
          ),
          if (resultado == ResultadoOcr.noCoincide && detectado != null) ...[
            const SizedBox(height: 10),
            Text(
              'Diferencia de ${formatearMonedaMxn((detectado - pago.transferAmount).abs())}. '
              'Revisa el comprobante antes de confirmar.',
              key: const Key('diferencia_ocr'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.error),
            ),
          ] else if (resultado == ResultadoOcr.sinLectura) ...[
            const SizedBox(height: 10),
            const Text(
              'No se pudo leer el monto del comprobante. Verifícalo manualmente.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _MontoEtiquetado extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;
  final bool alinearDerecha;

  const _MontoEtiquetado({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.color = AppColors.textPrimary,
    this.alinearDerecha = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alinearDerecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

/// Desglose de transferencia y efectivo.
class _Desglose extends StatelessWidget {
  final PagoEntity pago;
  final double? cuota;

  const _Desglose({required this.pago, this.cuota});

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      key: const Key('desglose_pago'),
      child: Column(
        children: [
          _FilaDesglose(
            key: const Key('desglose_transferencia'),
            icono: Icons.account_balance_outlined,
            etiqueta: 'Transferencia',
            valor: formatearMonedaMxn(pago.transferAmount),
          ),
          const SizedBox(height: 10),
          _FilaDesglose(
            key: const Key('desglose_efectivo'),
            icono: Icons.payments_outlined,
            etiqueta: 'Efectivo',
            valor: formatearMonedaMxn(pago.cashAmount),
          ),
          const Divider(height: 24),
          _FilaDesglose(
            key: const Key('desglose_total'),
            etiqueta: 'Total',
            valor: formatearMonedaMxn(pago.totalAmount),
            destacado: true,
          ),
          if (cuota != null) ...[
            const SizedBox(height: 6),
            _FilaDesglose(etiqueta: 'Cuota de la tanda', valor: formatearMonedaMxn(cuota!)),
          ],
        ],
      ),
    );
  }
}

class _FilaDesglose extends StatelessWidget {
  final IconData? icono;
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _FilaDesglose({super.key, this.icono, required this.etiqueta, required this.valor, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destacado ? 16 : 14,
      fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
      color: destacado ? AppColors.primaryDark : AppColors.textPrimary,
    );
    return Row(
      children: [
        if (icono != null) ...[Icon(icono, size: 18, color: AppColors.textSecondary), const SizedBox(width: 8)],
        Expanded(
          child: Text(etiqueta, style: estilo.copyWith(color: AppColors.textSecondary)),
        ),
        Text(valor, style: estilo),
      ],
    );
  }
}

class _BotonesRevision extends StatelessWidget {
  final bool habilitado;
  final AccionRevision accion;
  final VoidCallback onConfirmar;
  final VoidCallback onRechazar;

  const _BotonesRevision({
    required this.habilitado,
    required this.accion,
    required this.onConfirmar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final rechazando = accion == AccionRevision.rechazando;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              key: const Key('boton_rechazar_pago'),
              onPressed: habilitado ? onRechazar : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: rechazando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.error),
                    )
                  : const Text('Rechazar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            key: const Key('boton_confirmar_pago'),
            text: 'Confirmar',
            isLoading: accion == AccionRevision.confirmando,
            onPressed: habilitado ? onConfirmar : null,
          ),
        ),
      ],
    );
  }
}

/// Reemplaza los botones cuando el pago ya fue revisado.
class _ResultadoRevision extends StatelessWidget {
  final PagoEntity pago;

  const _ResultadoRevision({required this.pago});

  @override
  Widget build(BuildContext context) {
    final (color, icono, titulo) = pago.estaRechazado
        ? (AppColors.error, Icons.cancel_rounded, 'Pago rechazado')
        : (AppColors.success, Icons.verified_rounded, 'Pago confirmado');
    final motivo = pago.rejectionReason;

    return Container(
      key: const Key('resultado_revision'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                if (pago.estaRechazado && motivo != null && motivo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Motivo: $motivo', style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoRechazo extends StatefulWidget {
  const _DialogoRechazo();

  @override
  State<_DialogoRechazo> createState() => _DialogoRechazoState();
}

class _DialogoRechazoState extends State<_DialogoRechazo> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valido = RevisarPagoProvider.motivoValido(_controller.text);

    return AlertDialog(
      title: const Text('Rechazar pago'),
      content: TextField(
        key: const Key('campo_motivo_rechazo'),
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        maxLength: 500,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Motivo',
          hintText: 'Ej. El monto del comprobante no coincide',
          helperText: 'Mínimo 5 caracteres. El participante lo verá.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('boton_enviar_rechazo'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: valido ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Tarjeta({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('btn_reintentar_pago'),
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
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
      key: const Key('banner_error_revision'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje, style: const TextStyle(color: AppColors.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onCerrar,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
