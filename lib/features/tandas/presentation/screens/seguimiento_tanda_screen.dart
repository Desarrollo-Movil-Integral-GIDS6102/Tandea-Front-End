import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';
import 'package:tandea/features/tandas/presentation/providers/seguimiento_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/widgets/participante_seguimiento_item.dart';

/// Panel de seguimiento de la tanda: estado de pago de cada participante
/// en la vuelta actual, con pestañas Todos / Pagados / Pendientes / Atrasados.
class SeguimientoTandaScreen extends StatefulWidget {
  final String idTanda;

  /// Título mientras llega la respuesta del backend.
  final String? nombreTanda;

  const SeguimientoTandaScreen({super.key, required this.idTanda, this.nombreTanda});

  @override
  State<SeguimientoTandaScreen> createState() => _SeguimientoTandaScreenState();
}

class _SeguimientoTandaScreenState extends State<SeguimientoTandaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SeguimientoTandaProvider>().cargar(widget.idTanda);
      }
    });
  }

  Future<void> _recargar() => context.read<SeguimientoTandaProvider>().cargar(widget.idTanda);

  @override
  Widget build(BuildContext context) {
    final nombre = context.select<SeguimientoTandaProvider, String?>(
      (p) => p.seguimiento?.nombreTanda,
    );
    final titulo = (nombre != null && nombre.isNotEmpty) ? nombre : (widget.nombreTanda ?? 'Seguimiento');

    return DefaultTabController(
      length: FiltroSeguimiento.values.length,
      initialIndex: context.read<SeguimientoTandaProvider>().filtro.index,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(titulo),
          bottom: const _TabsSeguimiento(),
        ),
        body: _CuerpoSeguimiento(onRecargar: _recargar),
      ),
    );
  }
}

class _TabsSeguimiento extends StatelessWidget implements PreferredSizeWidget {
  const _TabsSeguimiento();

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    // Solo se reconstruye cuando cambian los conteos, no al cambiar de pestaña.
    final seguimiento = context.select<SeguimientoTandaProvider, SeguimientoTanda?>(
      (p) => p.seguimiento,
    );

    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      onTap: (index) =>
          context.read<SeguimientoTandaProvider>().cambiarFiltro(FiltroSeguimiento.values[index]),
      tabs: [
        for (final filtro in FiltroSeguimiento.values)
          Tab(
            key: Key('tab_seguimiento_${filtro.name}'),
            text: seguimiento == null
                ? filtro.etiqueta
                : '${filtro.etiqueta} (${seguimiento.participantes.where(filtro.incluye).length})',
          ),
      ],
    );
  }
}

class _CuerpoSeguimiento extends StatelessWidget {
  final Future<void> Function() onRecargar;

  const _CuerpoSeguimiento({required this.onRecargar});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeguimientoTandaProvider>();

    if (provider.seguimiento == null) {
      if (provider.isError) {
        return _MensajeEstado(
          icono: Icons.cloud_off_rounded,
          mensaje: provider.errorMessage ?? 'No pudimos cargar el seguimiento.',
          onReintentar: onRecargar,
        );
      }
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final cantidad = provider.cantidadFiltrados;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRecargar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _ProgresoVuelta()),
          if (cantidad == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _MensajeEstado(
                icono: Icons.inbox_outlined,
                mensaje: _mensajeVacio(provider.filtro),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: SliverList.builder(
                itemCount: cantidad,
                itemBuilder: (_, index) => ParticipanteSeguimientoItem(index: index),
              ),
            ),
        ],
      ),
    );
  }

  static String _mensajeVacio(FiltroSeguimiento filtro) => switch (filtro) {
        FiltroSeguimiento.todos => 'Esta tanda aún no tiene participantes.',
        FiltroSeguimiento.pagados => 'Nadie ha pagado en esta vuelta todavía.',
        FiltroSeguimiento.pendientes => 'No hay pagos pendientes.',
        FiltroSeguimiento.atrasados => 'Nadie está atrasado. ¡Todo en orden!',
      };
}

/// Tarjeta con la vuelta actual y la barra de pagos confirmados.
class _ProgresoVuelta extends StatelessWidget {
  const _ProgresoVuelta();

  @override
  Widget build(BuildContext context) {
    // El progreso solo cambia al recargar, no al cambiar de pestaña.
    final seguimiento = context.select<SeguimientoTandaProvider, SeguimientoTanda?>(
      (p) => p.seguimiento,
    )!;
    final porcentaje = (seguimiento.progreso * 100).round();
    final vuelta = seguimiento.totalVueltas != null
        ? 'Vuelta ${seguimiento.vueltaActual} de ${seguimiento.totalVueltas}'
        : 'Vuelta ${seguimiento.vueltaActual}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vuelta,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$porcentaje%',
                key: const Key('porcentaje_seguimiento'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: const Key('barra_progreso_seguimiento'),
              value: seguimiento.progreso,
              minHeight: 10,
              backgroundColor: AppColors.primaryLight,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${seguimiento.totalPagados} de ${seguimiento.participantes.length} pagos confirmados',
            key: const Key('texto_progreso_seguimiento'),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _MensajeEstado extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final VoidCallback? onReintentar;

  const _MensajeEstado({required this.icono, required this.mensaje, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('btn_reintentar_seguimiento'),
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
