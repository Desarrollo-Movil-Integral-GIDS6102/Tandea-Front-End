import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:tandea/features/notificaciones/presentation/providers/notificacion_provider.dart';

/// Bandeja de notificaciones con estado leído / no leído.
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificacionProvider>().cargar();
    });
  }

  void _abrir(NotificacionEntity n) {
    final provider = context.read<NotificacionProvider>();
    provider.marcarLeida(n);
    if (n.idTanda != null) context.push(RouteNames.tandaDetalle('${n.idTanda}'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificacionProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notificaciones')),
      body: SafeArea(child: _cuerpo(provider)),
    );
  }

  Widget _cuerpo(NotificacionProvider provider) {
    if (!provider.cargadoUnaVez) {
      if (provider.errorMessage != null && !provider.cargando) {
        return _Mensaje(
          icono: Icons.cloud_off_rounded,
          texto: provider.errorMessage!,
          onReintentar: provider.cargar,
        );
      }
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.cargar,
      child: provider.notificaciones.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              _Mensaje(icono: Icons.notifications_none_rounded, texto: 'No tienes notificaciones'),
            ])
          : ListView.separated(
              itemCount: provider.notificaciones.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = provider.notificaciones[i];
                return _NotificacionItem(notificacion: n, onTap: () => _abrir(n));
              },
            ),
    );
  }
}

class _NotificacionItem extends StatelessWidget {
  final NotificacionEntity notificacion;
  final VoidCallback onTap;

  const _NotificacionItem({required this.notificacion, required this.onTap});

  static IconData _icono(String tipo) => switch (tipo) {
        'pago_registrado' => Icons.receipt_long_rounded,
        'pago_confirmado' => Icons.check_circle_rounded,
        'pago_rechazado' => Icons.cancel_rounded,
        'recordatorio_pago' => Icons.alarm_rounded,
        'pago_vencido' => Icons.warning_amber_rounded,
        'turno_cobro_proximo' => Icons.event_available_rounded,
        'entrega_registrada' => Icons.payments_rounded,
        _ => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    final local = MaterialLocalizations.of(context);
    final fecha =
        '${local.formatShortDate(n.fecha)} · ${local.formatTimeOfDay(TimeOfDay.fromDateTime(n.fecha))}';

    return Material(
      color: n.leida ? AppColors.surface : AppColors.primaryLight.withValues(alpha: 0.35),
      child: ListTile(
        key: Key('notificacion_${n.idNotification}'),
        onTap: onTap,
        leading: Icon(_icono(n.tipo), color: n.leida ? AppColors.textDisabled : AppColors.primary),
        title: Text(
          n.mensaje,
          style: TextStyle(
            fontWeight: n.leida ? FontWeight.normal : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          [if (n.nombreTanda != null) n.nombreTanda!, fecha].join(' · '),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: n.leida
            ? null
            : Semantics(
                label: 'Sin leer',
                child: const CircleAvatar(radius: 5, backgroundColor: AppColors.primary),
              ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Future<void> Function()? onReintentar;

  const _Mensaje({required this.icono, required this.texto, this.onReintentar});

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
            Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
