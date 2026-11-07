import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/notificaciones/presentation/providers/notificacion_provider.dart';

/// Ícono de campana del AppBar con el contador de notificaciones no leídas.
class CampanaNotificaciones extends StatefulWidget {
  const CampanaNotificaciones({super.key});

  @override
  State<CampanaNotificaciones> createState() => _CampanaNotificacionesState();
}

class _CampanaNotificacionesState extends State<CampanaNotificaciones> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificacionProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = context.select<NotificacionProvider, int>((p) => p.noLeidas);
    return IconButton(
      key: const Key('btn_notificaciones'),
      tooltip: noLeidas == 0 ? 'Notificaciones' : 'Notificaciones, $noLeidas sin leer',
      onPressed: () => context.push(RouteNames.notificaciones),
      icon: Badge(
        isLabelVisible: noLeidas > 0,
        label: Text(noLeidas > 99 ? '99+' : '$noLeidas'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
