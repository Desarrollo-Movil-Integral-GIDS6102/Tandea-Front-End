import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/presentation/providers/admin_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/injection/injection.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _cargaInicialRealizada = false;

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
      if (esAdmin &&
          adminProvider != null &&
          adminProvider.metricas == null &&
          !adminProvider.isLoadingMetricas) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            adminProvider.cargarMetricas();
          }
        });
      }
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
              tooltip: 'Refrescar métricas',
              icon: const Icon(Icons.refresh),
              onPressed: adminProvider.isLoadingMetricas
                  ? null
                  : () => adminProvider.cargarMetricas(),
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
          : _CuerpoMetricasGlobal(provider: adminProvider),
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

class _CuerpoMetricasGlobal extends StatelessWidget {
  final AdminProvider provider;

  const _CuerpoMetricasGlobal({required this.provider});

  @override
  Widget build(BuildContext context) {
    final metricas = provider.metricas;

    if (provider.isLoadingMetricas && metricas == null) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('admin_metricas_loading'),
        ),
      );
    }

    if (provider.errorMetricas != null && metricas == null) {
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
                onPressed: provider.cargarMetricas,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (metricas == null) {
      return const _VistaResumenPlaceholder();
    }

    return RefreshIndicator(
      onRefresh: provider.cargarMetricas,
      child: ListView(
        key: const Key('admin_metricas_scroll'),
        padding: const EdgeInsets.all(16.0),
        children: [
          _EncabezadoMetricas(isLoading: provider.isLoadingMetricas),
          const SizedBox(height: 16),
          _GridKpisGlobal(metricas: metricas),
          const SizedBox(height: 24),
          _TarjetaGraficaMensual(montoPorMes: metricas.montoPorMes),
        ],
      ),
    );
  }
}

class _EncabezadoMetricas extends StatelessWidget {
  final bool isLoading;

  const _EncabezadoMetricas({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Métricas de Plataforma (AP-11)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Indicadores consolidados en tiempo real',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
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
                titulo: 'Usuarios',
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
                titulo: 'Tandas',
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
        const SizedBox(height: 12),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorIcono.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: colorIcono, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valorPrincipal,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (final detalle in detalles)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  detalle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
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
