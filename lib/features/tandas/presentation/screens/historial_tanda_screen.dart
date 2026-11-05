import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/tandas/domain/entities/movimiento_historial.dart';
import 'package:tandea/features/tandas/presentation/providers/historial_tanda_provider.dart';

/// Historial de pagos y cobros dentro de la tanda (AP-09), con scroll infinito.
///
/// El organizador ve todos los movimientos; un participante solo los suyos
/// (lo decide el backend).
class HistorialTandaScreen extends StatefulWidget {
  final String idTanda;
  final String? nombreTanda;

  const HistorialTandaScreen({super.key, required this.idTanda, this.nombreTanda});

  @override
  State<HistorialTandaScreen> createState() => _HistorialTandaScreenState();
}

class _HistorialTandaScreenState extends State<HistorialTandaScreen> {
  /// Distancia al final de la lista a la que se pide la siguiente página.
  static const double _umbralCargaPx = 300;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alHacerScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistorialTandaProvider>().cargar(widget.idTanda);
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_alHacerScroll)
      ..dispose();
    super.dispose();
  }

  void _alHacerScroll() {
    if (!_scroll.hasClients) return;
    final posicion = _scroll.position;
    if (posicion.pixels >= posicion.maxScrollExtent - _umbralCargaPx) {
      context.read<HistorialTandaProvider>().cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistorialTandaProvider>();
    final titulo = widget.nombreTanda == null ? 'Historial' : 'Historial · ${widget.nombreTanda}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(titulo)),
      body: SafeArea(child: _cuerpo(provider)),
    );
  }

  Widget _cuerpo(HistorialTandaProvider provider) {
    if (!provider.cargadoUnaVez) {
      if (provider.errorMessage != null && !provider.cargando) {
        return _MensajeEstado(
          icono: Icons.cloud_off_rounded,
          mensaje: provider.errorMessage!,
          onReintentar: provider.recargar,
        );
      }
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.vacio) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.recargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _MensajeEstado(
              icono: Icons.receipt_long_outlined,
              mensaje: 'Todavía no hay pagos ni cobros en esta tanda.',
            ),
          ],
        ),
      );
    }

    final movimientos = provider.movimientos;
    final conPie = provider.hayMas || provider.cargandoMas || provider.errorMessage != null;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.recargar,
      child: ListView.builder(
        key: const Key('lista_historial'),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: movimientos.length + (conPie ? 1 : 0),
        itemBuilder: (_, index) {
          if (index < movimientos.length) {
            return _MovimientoItem(movimiento: movimientos[index]);
          }
          return _PieLista(provider: provider);
        },
      ),
    );
  }
}

class _MovimientoItem extends StatelessWidget {
  final MovimientoHistorial movimiento;

  const _MovimientoItem({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final esCobro = movimiento.tipo == TipoMovimiento.cobro;
    final colorTipo = esCobro ? AppColors.info : AppColors.primary;
    final detalle = [
      if (movimiento.nombre != null && movimiento.nombre!.isNotEmpty) movimiento.nombre!,
      if (movimiento.fecha != null) _formatearFecha(movimiento.fecha!),
      if (!esCobro) movimiento.metodo,
    ].join(' · ');

    return Card(
      key: Key('movimiento_${movimiento.tipo.name}_${movimiento.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorTipo.withValues(alpha: 0.12),
          child: Icon(
            esCobro ? Icons.account_balance_wallet_outlined : Icons.payments_outlined,
            color: colorTipo,
          ),
        ),
        title: Text(
          '${movimiento.tipo.etiqueta} · Número ${movimiento.numero}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: detalle.isEmpty ? null : Text(detalle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatearMonedaMxn(movimiento.monto),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            _EstadoChip(movimiento: movimiento),
          ],
        ),
      ),
    );
  }

  static String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }
}

class _EstadoChip extends StatelessWidget {
  final MovimientoHistorial movimiento;

  const _EstadoChip({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final color = movimiento.esConfirmado
        ? AppColors.success
        : movimiento.esRechazado
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        movimiento.etiquetaEstado,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Último elemento de la lista: cargando la siguiente página o reintentar.
class _PieLista extends StatelessWidget {
  final HistorialTandaProvider provider;

  const _PieLista({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.errorMessage != null && !provider.cargandoMas) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(provider.errorMessage!, textAlign: TextAlign.center),
            TextButton(
              key: const Key('btn_reintentar_historial'),
              onPressed: provider.cargarMas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _MensajeEstado extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final Future<void> Function()? onReintentar;

  const _MensajeEstado({required this.icono, required this.mensaje, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            if (onReintentar != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onReintentar, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
