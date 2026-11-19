import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_detalle_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/admin/presentation/providers/admin_provider.dart';

class AdminCasoDetalleScreen extends StatefulWidget {
  final int idDispute;
  final AdminDisputaEntity? disputaInicial;

  const AdminCasoDetalleScreen({
    super.key,
    required this.idDispute,
    this.disputaInicial,
  });

  @override
  State<AdminCasoDetalleScreen> createState() => _AdminCasoDetalleScreenState();
}

class _AdminCasoDetalleScreenState extends State<AdminCasoDetalleScreen> {
  bool _cargaIniciada = false;
  final TextEditingController _notasController = TextEditingController();

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cargaIniciada) {
      _cargaIniciada = true;
      final provider = Provider.of<AdminProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          provider.cargarDetalleDisputa(widget.idDispute);
        }
      });
    }
  }

  Future<void> _ejecutarResolucion(
    BuildContext context,
    AdminProvider provider,
  ) async {
    final exito = await provider.resolverDisputa(widget.idDispute);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito
              ? 'Caso #${widget.idDispute} resuelto correctamente.'
              : (provider.errorDetalleDisputa ?? 'No se pudo resolver el caso.'),
        ),
      ),
    );
  }

  void _mostrarVistaPreviaEvidencia(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('dialog_vista_previa_evidencia'),
        title: const Text('Evidencia del caso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'URL del comprobante adjunto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(
              url,
              key: const Key('texto_url_evidencia_dialog'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('btn_cerrar_evidencia_dialog'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final detalle = provider.detalleDisputaActual;
    final disputa = detalle?.disputa ?? widget.disputaInicial;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Caso #${widget.idDispute}'),
        actions: [
          IconButton(
            key: const Key('btn_refrescar_detalle_caso'),
            tooltip: 'Refrescar caso',
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoadingDetalleDisputa
                ? null
                : () => provider.cargarDetalleDisputa(
                      widget.idDispute,
                      reiniciarFormulario: false,
                    ),
          ),
        ],
      ),
      body: _buildBody(context, provider, detalle, disputa),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminProvider provider,
    AdminDisputaDetalleEntity? detalle,
    AdminDisputaEntity? disputa,
  ) {
    if (provider.isLoadingDetalleDisputa && detalle == null && disputa == null) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('caso_detalle_loading'),
        ),
      );
    }

    if (provider.errorDetalleDisputa != null &&
        detalle == null &&
        disputa == null) {
      return Center(
        key: const Key('caso_detalle_error'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorDetalleDisputa!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('btn_reintentar_detalle_caso'),
                onPressed: () => provider.cargarDetalleDisputa(widget.idDispute),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (disputa == null) {
      return const Center(
        child: Text('No se encontró información del caso.'),
      );
    }

    final eventos = detalle?.lineaTiempo ??
        AdminDisputaDetalleEntity(disputa: disputa).lineaTiempo;

    return SingleChildScrollView(
      key: const Key('caso_detalle_scroll'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EncabezadoCasoCard(disputa: disputa),
          const SizedBox(height: 20),
          _SeccionLineaTiempoCaso(
            eventos: eventos,
            onVerEvidencia: (url) => _mostrarVistaPreviaEvidencia(context, url),
          ),
          const SizedBox(height: 20),
          if (disputa.puedeResolverse)
            _SeccionResolucionCaso(
              provider: provider,
              notasController: _notasController,
              onResolver: () => _ejecutarResolucion(context, provider),
            )
          else
            _TarjetaCasoResuelto(disputa: disputa),
        ],
      ),
    );
  }
}

class _EncabezadoCasoCard extends StatelessWidget {
  final AdminDisputaEntity disputa;

  const _EncabezadoCasoCard({required this.disputa});

  Color _colorEstado(String status) {
    switch (status.toUpperCase()) {
      case 'ABIERTA':
        return AppColors.error;
      case 'EN_REVISION':
        return AppColors.warning;
      case 'RESUELTA':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorEstado(disputa.status);

    return Card(
      key: const Key('caso_encabezado_card'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Caso #${disputa.idDispute} • ${disputa.nombreTanda}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  key: const Key('caso_estado_chip'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    disputa.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Motivo reportado:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              disputa.reason,
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reportante: ${disputa.nombreReporter} (${disputa.emailReporter})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeccionLineaTiempoCaso extends StatelessWidget {
  final List<EventoLineaTiempoCaso> eventos;
  final ValueChanged<String> onVerEvidencia;

  const _SeccionLineaTiempoCaso({
    required this.eventos,
    required this.onVerEvidencia,
  });

  IconData _iconoPorTipo(TipoEventoCaso tipo) {
    switch (tipo) {
      case TipoEventoCaso.pagoEntrega:
        return Icons.payments_outlined;
      case TipoEventoCaso.confirmacion:
        return Icons.verified_outlined;
      case TipoEventoCaso.evidencia:
        return Icons.image_outlined;
      case TipoEventoCaso.reporte:
        return Icons.report_problem_outlined;
      case TipoEventoCaso.auditoria:
        return Icons.history_edu_outlined;
      case TipoEventoCaso.resolucion:
        return Icons.gavel_outlined;
    }
  }

  Color _colorPorTipo(TipoEventoCaso tipo) {
    switch (tipo) {
      case TipoEventoCaso.pagoEntrega:
        return AppColors.primary;
      case TipoEventoCaso.confirmacion:
        return AppColors.info;
      case TipoEventoCaso.evidencia:
        return AppColors.secondary;
      case TipoEventoCaso.reporte:
        return AppColors.error;
      case TipoEventoCaso.auditoria:
        return AppColors.textSecondary;
      case TipoEventoCaso.resolucion:
        return AppColors.success;
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('caso_linea_tiempo'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Línea de tiempo del caso',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pagos, confirmaciones, evidencias y bitácora en orden cronológico',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < eventos.length; i++)
              _ItemLineaTiempo(
                index: i,
                evento: eventos[i],
                esUltimo: i == eventos.length - 1,
                icono: _iconoPorTipo(eventos[i].tipo),
                color: _colorPorTipo(eventos[i].tipo),
                fechaTexto: _formatearFecha(eventos[i].fecha),
                onVerEvidencia: onVerEvidencia,
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemLineaTiempo extends StatelessWidget {
  final int index;
  final EventoLineaTiempoCaso evento;
  final bool esUltimo;
  final IconData icono;
  final Color color;
  final String fechaTexto;
  final ValueChanged<String> onVerEvidencia;

  const _ItemLineaTiempo({
    required this.index,
    required this.evento,
    required this.esUltimo,
    required this.icono,
    required this.color,
    required this.fechaTexto,
    required this.onVerEvidencia,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      key: Key('timeline_evento_$index'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(icono, size: 18, color: color),
              ),
              if (!esUltimo)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          evento.titulo,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (evento.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            evento.badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (fechaTexto.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      fechaTexto,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    evento.descripcion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (evento.evidenceUrl != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      key: Key('timeline_evidencia_url_$index'),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attachment,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              evento.evidenceUrl!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                          TextButton(
                            key: Key('btn_ver_evidencia_$index'),
                            onPressed: () =>
                                onVerEvidencia(evento.evidenceUrl!),
                            child: const Text('Ver evidencia'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionResolucionCaso extends StatelessWidget {
  final AdminProvider provider;
  final TextEditingController notasController;
  final VoidCallback onResolver;

  const _SeccionResolucionCaso({
    required this.provider,
    required this.notasController,
    required this.onResolver,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accionActual = provider.accionSeleccionada;

    return Card(
      key: const Key('seccion_resolucion_caso'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resolver caso',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona una decisión y redacta el comentario obligatorio de auditoría.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BotonOpcionAccion(
                    optionKey: const Key('opcion_accion_mantener'),
                    etiqueta: 'Mantener',
                    subtitulo: 'Validar estado actual',
                    icono: Icons.check_circle_outline,
                    color: AppColors.success,
                    seleccionado: accionActual == 'mantener',
                    onTap: () => provider.seleccionarAccionResolucion('mantener'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotonOpcionAccion(
                    optionKey: const Key('opcion_accion_revertir'),
                    etiqueta: 'Revertir',
                    subtitulo: 'Revertir operación',
                    icono: Icons.undo_rounded,
                    color: AppColors.warning,
                    seleccionado: accionActual == 'revertir',
                    onTap: () => provider.seleccionarAccionResolucion('revertir'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotonOpcionAccion(
                    optionKey: const Key('opcion_accion_suspender'),
                    etiqueta: 'Suspender',
                    subtitulo: 'Suspender tanda',
                    icono: Icons.block_outlined,
                    color: AppColors.error,
                    seleccionado: accionActual == 'suspender',
                    onTap: () => provider.seleccionarAccionResolucion('suspender'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('input_notas_resolucion'),
              controller: notasController,
              onChanged: provider.actualizarNotasResolucion,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario de resolución *',
                hintText:
                    'Describe los fundamentos y evidencias revisadas para resolver la disputa...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('btn_resolver_caso'),
              onPressed: provider.puedeConfirmarResolucion ? onResolver : null,
              icon: provider.isResolviendoDisputa
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.gavel),
              label: const Text('Resolver caso'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonOpcionAccion extends StatelessWidget {
  final Key optionKey;
  final String etiqueta;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonOpcionAccion({
    required this.optionKey,
    required this.etiqueta,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: optionKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: seleccionado
              ? color.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado ? color : AppColors.border,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: seleccionado ? color : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              etiqueta,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: seleccionado ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaCasoResuelto extends StatelessWidget {
  final AdminDisputaEntity disputa;

  const _TarjetaCasoResuelto({required this.disputa});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('tarjeta_caso_resuelto'),
      elevation: 0,
      color: AppColors.success.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disputa resuelta',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disputa.resolutionNotes ??
                        'El caso fue cerrado por el Administrador Global.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
