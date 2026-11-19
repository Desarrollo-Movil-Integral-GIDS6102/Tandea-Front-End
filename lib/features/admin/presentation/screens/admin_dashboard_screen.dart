import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_usuario_entity.dart';
import 'package:tandea/features/admin/presentation/providers/admin_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/injection/injection.dart';

class AdminDashboardScreen extends StatefulWidget {
  final void Function(AdminDisputaEntity disputa)? onDisputaSelected;

  const AdminDashboardScreen({
    super.key,
    this.onDisputaSelected,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _cargaInicialRealizada = false;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final adminProvider = _obtenerAdminProvider(context, listen: false);
    adminProvider?.setActiveTabIndex(_tabController.index);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  AuthSessionProvider? _obtenerSesion(BuildContext context) {
    try {
      return Provider.of<AuthSessionProvider>(context);
    } catch (_) {
      if (sl.isRegistered<AuthSessionProvider>()) {
        return sl<AuthSessionProvider>();
      }
      return null;
    }
  }

  AdminProvider? _obtenerAdminProvider(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<AdminProvider>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cargaInicialRealizada) {
      _cargaInicialRealizada = true;
      final sesion = _obtenerSesion(context);
      final esAdmin = sesion?.isAdminGlobal ?? false;
      final adminProvider = _obtenerAdminProvider(context, listen: false);
      if (esAdmin && adminProvider != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            adminProvider.cargarTodo();
          }
        });
      }
    }
  }

  void _onSearchChanged(String value, AdminProvider provider) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        provider.aplicarBusqueda(value);
      }
    });
  }

  Future<void> _mostrarDialogoSuspension(
    BuildContext context,
    AdminProvider provider,
    AdminUsuarioEntity usuario,
  ) async {
    String motivoCapturado = '';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('dialog_confirmar_suspension'),
          title: const Text('Suspender usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas suspender a ${usuario.nombreCompleto} (${usuario.email})?',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_motivo_suspension'),
                onChanged: (value) => motivoCapturado = value,
                decoration: const InputDecoration(
                  labelText: 'Motivo de suspensión (opcional)',
                  hintText: 'Ej. Impago reiterado o incumplimiento',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('btn_cancelar_suspension'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              key: const Key('btn_confirmar_suspension'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmar suspensión'),
            ),
          ],
        );
      },
    );

    final motivo = motivoCapturado.trim();

    if (confirmado == true && context.mounted) {
      final exito = await provider.suspenderUsuario(
        usuario.idUser,
        motivo: motivo.isEmpty ? null : motivo,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exito
                  ? 'Usuario ${usuario.nombreCompleto} suspendido correctamente.'
                  : (provider.errorUsuarios ?? 'No se pudo suspender al usuario.'),
            ),
          ),
        );
      }
    }
  }

  void _abrirDetalleDisputa(BuildContext context, AdminDisputaEntity disputa) {
    if (widget.onDisputaSelected != null) {
      widget.onDisputaSelected!(disputa);
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push(
        RouteNames.adminDisputaDetalle(disputa.idDispute),
        extra: disputa,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = _obtenerSesion(context);
    final esAdminGlobal = sesion?.isAdminGlobal ?? false;

    if (!esAdminGlobal) {
      return _VistaAccesoRestringido(
        onVolver: () {
          final router = GoRouter.maybeOf(context);
          if (router != null) {
            router.go(RouteNames.tandasParticipante);
          }
        },
      );
    }

    final adminProvider = _obtenerAdminProvider(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador Global'),
        elevation: 0,
        actions: [
          if (adminProvider != null)
            IconButton(
              key: const Key('btn_admin_refrescar'),
              tooltip: 'Refrescar panel',
              icon: const Icon(Icons.refresh),
              onPressed: adminProvider.isLoading
                  ? null
                  : () => adminProvider.cargarTodo(),
            ),
          IconButton(
            key: const Key('btn_admin_perfil'),
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(RouteNames.perfil),
          ),
        ],
      ),
      body: adminProvider == null
          ? const _VistaResumenPlaceholder()
          : _CuerpoPanelAdmin(
              provider: adminProvider,
              tabController: _tabController,
              searchController: _searchController,
              onSearchChanged: (val) => _onSearchChanged(val, adminProvider),
              onClearSearch: () {
                _debounceTimer?.cancel();
                _searchController.clear();
                adminProvider.aplicarBusqueda('');
              },
              onSuspenderUsuario: (u) =>
                  _mostrarDialogoSuspension(context, adminProvider, u),
              onSeleccionarDisputa: (d) => _abrirDetalleDisputa(context, d),
            ),
    );
  }
}

class _VistaAccesoRestringido extends StatelessWidget {
  final VoidCallback onVolver;

  const _VistaAccesoRestringido({required this.onVolver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('admin_acceso_restringido'),
      appBar: AppBar(
        title: const Text('Acceso restringido'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 72,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Acceso exclusivo para Administrador Global',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu cuenta no cuenta con el rol admin_global necesario para consultar este panel.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('btn_volver_inicio'),
                onPressed: onVolver,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Ir a mis tandas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VistaResumenPlaceholder extends StatelessWidget {
  const _VistaResumenPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 88,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Panel Administrador Global',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Flujo exclusivo de gestión global: métricas de plataforma, usuarios, tandas activas y resolución de disputas.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CuerpoPanelAdmin extends StatelessWidget {
  final AdminProvider provider;
  final TabController tabController;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<AdminUsuarioEntity> onSuspenderUsuario;
  final ValueChanged<AdminDisputaEntity> onSeleccionarDisputa;

  const _CuerpoPanelAdmin({
    required this.provider,
    required this.tabController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSuspenderUsuario,
    required this.onSeleccionarDisputa,
  });

  @override
  Widget build(BuildContext context) {
    final metricas = provider.metricas;
    final sinDatosCargados = metricas == null &&
        provider.usuarios.isEmpty &&
        provider.tandas.isEmpty &&
        provider.disputas.isEmpty;

    if (provider.isLoadingMetricas && sinDatosCargados) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('admin_metricas_loading'),
        ),
      );
    }

    if (provider.errorMetricas != null && sinDatosCargados) {
      return Center(
        key: const Key('admin_metricas_error'),
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
                provider.errorMetricas!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('btn_reintentar_metricas'),
                onPressed: provider.cargarTodo,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.cargarTodo,
      child: SingleChildScrollView(
        key: const Key('admin_metricas_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (metricas != null) ...[
              _GridKpisGlobal(metricas: metricas),
              const SizedBox(height: 16),
            ],
            _SeccionGestionAdmin(
              provider: provider,
              tabController: tabController,
              searchController: searchController,
              onSearchChanged: onSearchChanged,
              onClearSearch: onClearSearch,
              onSuspenderUsuario: onSuspenderUsuario,
              onSeleccionarDisputa: onSeleccionarDisputa,
            ),
            if (metricas != null) ...[
              const SizedBox(height: 20),
              _TarjetaGraficaMensual(montoPorMes: metricas.montoPorMes),
            ],
          ],
        ),
      ),
    );
  }
}

class _GridKpisGlobal extends StatelessWidget {
  final AdminMetricasEntity metricas;

  const _GridKpisGlobal({required this.metricas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KpiCard(
                cardKey: const Key('kpi_usuarios_card'),
                titulo: 'Total Usuarios',
                valorPrincipal: '${metricas.usuarios.total}',
                icono: Icons.people_alt_outlined,
                colorIcono: AppColors.primary,
                detalles: [
                  '${metricas.usuarios.activos} activos',
                  '${metricas.usuarios.suspendidos} suspendidos',
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                cardKey: const Key('kpi_tandas_card'),
                titulo: 'Total Tandas',
                valorPrincipal: '${metricas.tandas.total}',
                icono: Icons.autorenew_rounded,
                colorIcono: AppColors.info,
                detalles: [
                  '${metricas.tandas.activas} activas',
                  '${metricas.tandas.pendientes} pendientes',
                  '${metricas.tandas.finalizadas} finalizadas',
                  '${metricas.tandas.suspendidas} suspendidas',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KpiCard(
                cardKey: const Key('kpi_monto_card'),
                titulo: 'Monto total gestionado',
                valorPrincipal: formatearMonedaMxn(metricas.montoGestionado),
                icono: Icons.payments_outlined,
                colorIcono: AppColors.success,
                detalles: const ['Pagos confirmados en MXN'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                cardKey: const Key('kpi_disputas_card'),
                titulo: 'Disputas pendientes',
                valorPrincipal: '${metricas.disputasPendientes}',
                icono: Icons.gavel_outlined,
                colorIcono: metricas.disputasPendientes > 0
                    ? AppColors.warning
                    : AppColors.textSecondary,
                detalles: const ['Abiertas o en revisión'],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final Key cardKey;
  final String titulo;
  final String valorPrincipal;
  final IconData icono;
  final Color colorIcono;
  final List<String> detalles;

  const _KpiCard({
    required this.cardKey,
    required this.titulo,
    required this.valorPrincipal,
    required this.icono,
    required this.colorIcono,
    required this.detalles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: cardKey,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: colorIcono, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              valorPrincipal,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                for (final detalle in detalles)
                  Text(
                    detalle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
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

class _SeccionGestionAdmin extends StatelessWidget {
  final AdminProvider provider;
  final TabController tabController;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<AdminUsuarioEntity> onSuspenderUsuario;
  final ValueChanged<AdminDisputaEntity> onSeleccionarDisputa;

  const _SeccionGestionAdmin({
    required this.provider,
    required this.tabController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSuspenderUsuario,
    required this.onSeleccionarDisputa,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('admin_search_bar'),
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar usuarios, tandas o casos reportados...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isNotEmpty ||
                    provider.searchQuery.isNotEmpty
                ? IconButton(
                    key: const Key('btn_clear_search'),
                    icon: const Icon(Icons.clear),
                    onPressed: onClearSearch,
                  )
                : null,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            return Container(
              key: const Key('admin_tab_bar'),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  _TabBotonAdmin(
                    tabKey: const Key('tab_admin_usuarios'),
                    titulo: 'Usuarios',
                    activo: tabController.index == 0,
                    onTap: () => tabController.animateTo(0),
                  ),
                  _TabBotonAdmin(
                    tabKey: const Key('tab_admin_tandas'),
                    titulo: 'Tandas',
                    activo: tabController.index == 1,
                    onTap: () => tabController.animateTo(1),
                  ),
                  _TabBotonAdmin(
                    tabKey: const Key('tab_admin_casos'),
                    titulo: 'Casos',
                    activo: tabController.index == 2,
                    onTap: () => tabController.animateTo(2),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            switch (tabController.index) {
              case 0:
                return _ListaUsuariosTab(
                  usuarios: provider.usuariosFiltrados,
                  isLoading: provider.isLoadingUsuarios,
                  onSuspender: onSuspenderUsuario,
                );
              case 1:
                return _ListaTandasTab(
                  tandas: provider.tandasFiltradas,
                  isLoading: provider.isLoadingTandas,
                );
              case 2:
              default:
                return _ListaCasosTab(
                  disputas: provider.disputasFiltradas,
                  isLoading: provider.isLoadingDisputas,
                  onSeleccionarDisputa: onSeleccionarDisputa,
                );
            }
          },
        ),
      ],
    );
  }
}

class _TabBotonAdmin extends StatelessWidget {
  final Key tabKey;
  final String titulo;
  final bool activo;
  final VoidCallback onTap;

  const _TabBotonAdmin({
    required this.tabKey,
    required this.titulo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        key: tabKey,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: activo ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            titulo,
            style: TextStyle(
              color: color,
              fontWeight: activo ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListaUsuariosTab extends StatelessWidget {
  final List<AdminUsuarioEntity> usuarios;
  final bool isLoading;
  final ValueChanged<AdminUsuarioEntity> onSuspender;

  const _ListaUsuariosTab({
    required this.usuarios,
    required this.isLoading,
    required this.onSuspender,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && usuarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (usuarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No se encontraron usuarios',
            key: Key('admin_usuarios_vacio'),
          ),
        ),
      );
    }

    return Column(
      key: const Key('admin_lista_usuarios'),
      children: [
        for (final usuario in usuarios)
          Card(
            key: Key('usuario_item_${usuario.idUser}'),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              title: Text(
                usuario.nombreCompleto,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.email),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _ChipEstado(
                        etiqueta: usuario.active ? 'Activo' : 'Suspendido',
                        color: usuario.active ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rol: ${usuario.role}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: usuario.puedeSuspenderse
                  ? OutlinedButton(
                      key: Key('btn_suspender_usuario_${usuario.idUser}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () => onSuspender(usuario),
                      child: const Text('Suspender'),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ListaTandasTab extends StatelessWidget {
  final List<TandaEntity> tandas;
  final bool isLoading;

  const _ListaTandasTab({
    required this.tandas,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && tandas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (tandas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No se encontraron tandas',
            key: Key('admin_tandas_vacio'),
          ),
        ),
      );
    }

    return Column(
      key: const Key('admin_lista_tandas'),
      children: [
        for (final tanda in tandas)
          Card(
            key: Key('tanda_item_${tanda.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              title: Text(
                tanda.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${formatearMonedaMxn(tanda.monto)} • ${tanda.totalParticipantes} participantes • ${tanda.periodo}'
                '${tanda.inviteCode != null ? ' • Código: ${tanda.inviteCode}' : ''}',
              ),
              trailing: _ChipEstado(
                etiqueta: tanda.estado.toUpperCase(),
                color: tanda.esActiva
                    ? AppColors.success
                    : (tanda.esPendiente ? AppColors.warning : AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _ListaCasosTab extends StatelessWidget {
  final List<AdminDisputaEntity> disputas;
  final bool isLoading;
  final ValueChanged<AdminDisputaEntity> onSeleccionarDisputa;

  const _ListaCasosTab({
    required this.disputas,
    required this.isLoading,
    required this.onSeleccionarDisputa,
  });

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
    if (isLoading && disputas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (disputas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No se encontraron casos reportados',
            key: Key('admin_casos_vacio'),
          ),
        ),
      );
    }

    return Column(
      key: const Key('admin_lista_casos'),
      children: [
        for (final disputa in disputas)
          Card(
            key: Key('disputa_item_${disputa.idDispute}'),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              onTap: () => onSeleccionarDisputa(disputa),
              title: Text(
                'Caso #${disputa.idDispute} • ${disputa.nombreTanda}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(disputa.reason),
                  const SizedBox(height: 4),
                  Text(
                    'Reportado por: ${disputa.nombreReporter} (${disputa.emailReporter})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              trailing: _ChipEstado(
                etiqueta: disputa.status,
                color: _colorEstado(disputa.status),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final String etiqueta;
  final Color color;

  const _ChipEstado({
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _TarjetaGraficaMensual extends StatelessWidget {
  final List<MontoMensual> montoPorMes;

  const _TarjetaGraficaMensual({required this.montoPorMes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMonto = montoPorMes.isEmpty
        ? 0.0
        : montoPorMes.map((e) => e.monto).reduce(math.max);
    final maxY = maxMonto <= 0 ? 1000.0 : maxMonto * 1.2;

    return Card(
      key: const Key('admin_grafica_card'),
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
            Text(
              'Monto gestionado por mes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Evolución de pagos confirmados (últimos 12 meses)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (montoPorMes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'Sin movimientos registrados en los últimos 12 meses',
                    key: Key('admin_grafica_vacia'),
                  ),
                ),
              )
            else
              SizedBox(
                height: 240,
                child: BarChart(
                  key: const Key('admin_metricas_bar_chart'),
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = montoPorMes[group.x];
                          return BarTooltipItem(
                            '${item.mes}\n${formatearMonedaMxn(item.monto)}\n(${item.pagos} pagos)',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return const Text(
                                r'$0',
                                style: TextStyle(fontSize: 10),
                              );
                            }
                            final abreviado = value >= 1000
                                ? '\$${(value / 1000).toStringAsFixed(1)}k'
                                : '\$${value.toInt()}';
                            return Text(
                              abreviado,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= montoPorMes.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                montoPorMes[idx].etiquetaMes,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(
                      montoPorMes.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: montoPorMes[index].monto,
                            color: AppColors.primary,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
