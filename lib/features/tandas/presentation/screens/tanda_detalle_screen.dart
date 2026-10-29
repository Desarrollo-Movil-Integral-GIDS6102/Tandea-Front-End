import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/pagos/presentation/screens/registrar_pago_screen.dart';
import 'package:tandea/features/tandas/domain/entities/numero_tanda.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/presentation/providers/tanda_detalle_provider.dart';

/// Detalle de una tanda para participantes y organizador.
///
/// Siempre se puede consultar; es de solo lectura (no edita ni borra la tanda).
/// El pago de cada número se habilita únicamente cuando la tanda está ACTIVA.
class TandaDetalleScreen extends StatelessWidget {
  final String idTanda;

  const TandaDetalleScreen({super.key, required this.idTanda});

  Future<void> _recargar(BuildContext context) =>
      context.read<TandaDetalleProvider>().cargar(idTanda);

  Future<void> _apartarNumeros(BuildContext context, TandaEntity tanda) async {
    await context.push(RouteNames.seleccionarNumero, extra: tanda);
    if (context.mounted) await _recargar(context);
  }

  Future<void> _pagar(BuildContext context, TandaEntity tanda, NumeroTanda numero) async {
    await context.push(
      RouteNames.registrarPago,
      extra: RegistrarPagoArgs(
        nombreTanda: tanda.nombre,
        idNumber: numero.idNumber,
        cuota: tanda.monto,
        numeroTurno: numero.numberValue,
        vuelta: numero.roundNumber,
      ),
    );
    if (context.mounted) await _recargar(context);
  }

  Future<void> _iniciar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Iniciar la tanda?'),
        content: const Text(
          'Ya no se podrán apartar números y los participantes podrán empezar a pagar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            key: const Key('btn_confirmar_iniciar_tanda'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    await context.read<TandaDetalleProvider>().iniciar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TandaDetalleProvider>();
    final tanda = provider.tanda;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(tanda?.nombre ?? 'Detalle de la tanda'),
        actions: [
          if (tanda != null && tanda.esOrganizador && (tanda.inviteCode?.isNotEmpty ?? false))
            IconButton(
              key: const Key('btn_detalle_compartir'),
              tooltip: 'Compartir código',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => context.push(RouteNames.compartirCodigo, extra: tanda),
            ),
        ],
      ),
      body: SafeArea(
        child: tanda == null
            ? Center(
                child: provider.cargando
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.errorMessage ?? 'No se pudo cargar la tanda.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _recargar(context),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
              )
            : RefreshIndicator(
                onRefresh: () => _recargar(context),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Resumen(tanda: tanda),
                    const SizedBox(height: 16),
                    _AvisoEstado(tanda: tanda),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        key: const Key('detalle_error'),
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _MisNumeros(
                      tanda: tanda,
                      onPagar: (n) => _pagar(context, tanda, n),
                    ),
                    if (tanda.aceptaNumeros) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('btn_apartar_numeros'),
                        onPressed: () => _apartarNumeros(context, tanda),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: Text(
                          tanda.misNumeros.isEmpty ? 'Apartar mis números' : 'Apartar más números',
                        ),
                      ),
                    ],
                    if (tanda.esOrganizador && tanda.esPendiente) ...[
                      const SizedBox(height: 12),
                      _BotonIniciar(
                        tanda: tanda,
                        iniciando: provider.iniciando,
                        onIniciar: () => _iniciar(context),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _TablaNumeros(tanda: tanda),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final TandaEntity tanda;

  const _Resumen({required this.tanda});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tanda.inviteCode ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Chip(
                  key: const Key('detalle_estado'),
                  label: Text(tanda.estado.toUpperCase()),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24),
            _Fila('Cuota por número', formatearMonedaMxn(tanda.monto)),
            _Fila('Periodicidad', tanda.periodo.toUpperCase()),
            _Fila('Números', '${tanda.totalParticipantes}'),
            _Fila('Cobro por turno', formatearMonedaMxn(tanda.monto * tanda.totalParticipantes)),
            if (tanda.startDate != null) _Fila('Inicio', tanda.startDate!.split('T').first),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label;
  final String valor;

  const _Fila(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AvisoEstado extends StatelessWidget {
  final TandaEntity tanda;

  const _AvisoEstado({required this.tanda});

  @override
  Widget build(BuildContext context) {
    final String texto;
    if (tanda.esActiva) {
      texto = 'La tanda está en curso. Ya puedes registrar los pagos de tus números.';
    } else if (tanda.esPendiente) {
      final libres = tanda.numerosDisponibles?.length ?? 0;
      texto = 'La tanda aún no inicia${libres > 0 ? ' (quedan $libres números libres)' : ''}. '
          'Los pagos se habilitan cuando el organizador la inicie.';
    } else {
      texto = 'Esta tanda está ${tanda.estado.toLowerCase()}.';
    }

    return Container(
      key: const Key('detalle_aviso_estado'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _MisNumeros extends StatelessWidget {
  final TandaEntity tanda;
  final ValueChanged<NumeroTanda> onPagar;

  const _MisNumeros({required this.tanda, required this.onPagar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mis números',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (tanda.misNumeros.isEmpty)
          const Text(
            'Aún no tienes números en esta tanda.',
            style: TextStyle(color: AppColors.textSecondaryLight),
          )
        else
          for (final n in tanda.misNumeros)
            Card(
              key: Key('mi_numero_${n.numberValue}'),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '${n.numberValue}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text('Número #${n.numberValue}'),
                subtitle: Text('Vuelta ${n.roundNumber}'),
                trailing: ElevatedButton(
                  key: Key('btn_pagar_numero_${n.numberValue}'),
                  // Pagar solo cuando el organizador ya inició la tanda
                  onPressed: tanda.esActiva ? () => onPagar(n) : null,
                  child: const Text('Pagar'),
                ),
              ),
            ),
      ],
    );
  }
}

class _BotonIniciar extends StatelessWidget {
  final TandaEntity tanda;
  final bool iniciando;
  final VoidCallback onIniciar;

  const _BotonIniciar({required this.tanda, required this.iniciando, required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    final faltan = tanda.numerosDisponibles?.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          key: const Key('btn_iniciar_tanda'),
          onPressed: faltan == 0 && !iniciando ? onIniciar : null,
          icon: iniciando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar tanda'),
        ),
        if (faltan > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Faltan $faltan números por apartar para poder iniciar.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
          ),
      ],
    );
  }
}

class _TablaNumeros extends StatelessWidget {
  final TandaEntity tanda;

  const _TablaNumeros({required this.tanda});

  @override
  Widget build(BuildContext context) {
    final porNumero = {
      for (final n in tanda.numeros.where((n) => n.roundNumber == 1)) n.numberValue: n,
    };
    // El número muerto siempre es el #0; los participantes van de #1 a #N
    final primero = tanda.hasDeadNumber == true ? 0 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Números de la tanda',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var valor = primero; valor <= tanda.totalParticipantes; valor++)
          ListTile(
            key: Key('fila_numero_$valor'),
            dense: true,
            leading: Text('#$valor', style: const TextStyle(fontWeight: FontWeight.bold)),
            title: Text(switch (porNumero[valor]) {
              _ when valor == 0 => 'Número muerto (caja)',
              null => 'Disponible',
              final n => n.userName ?? 'Apartado',
            }),
          ),
      ],
    );
  }
}
