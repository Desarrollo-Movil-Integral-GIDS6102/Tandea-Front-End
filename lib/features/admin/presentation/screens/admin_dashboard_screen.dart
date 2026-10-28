import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/core/routes/route_names.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador Global'),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('btn_admin_perfil'),
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(RouteNames.perfil),
          ),
        ],
      ),
      body: Center(
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
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Flujo exclusivo de gestión global: métricas de plataforma, usuarios, tandas activas y resolución de disputas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
