import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/tandas/presentation/screens/mis_tandas_organizador_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/mis_tandas_participante_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/tandas_navigation_screen.dart';
import 'package:tandea/injection/injection.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.initial,
    refreshListenable: sl<AuthSessionProvider>(),
    redirect: (context, state) {
      final session = sl<AuthSessionProvider>();
      final loc = state.matchedLocation;

      // Si el rol es Admin Global, el flujo redirige hacia /admin
      if (session.isAdminGlobal) {
        if (loc == RouteNames.initial ||
            loc == RouteNames.tandas ||
            loc == RouteNames.tandasParticipante ||
            loc == RouteNames.tandasOrganizador) {
          return RouteNames.admin;
        }
      } else {
        // Si es usuario normal, la ruta raíz o /tandas redirige a la pestaña de participante
        if (loc == RouteNames.initial || loc == RouteNames.tandas) {
          return RouteNames.tandasParticipante;
        }
      }
      return null;
    },
    routes: [
      // Flujo de Tandas con BottomNavigationBar (Participante / Organizador)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TandasNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.tandasParticipante,
                builder: (context, state) =>
                    const MisTandasParticipanteScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.tandasOrganizador,
                builder: (context, state) =>
                    const MisTandasOrganizadorScreen(),
              ),
            ],
          ),
        ],
      ),

      // Flujo del Administrador Global
      GoRoute(
        path: RouteNames.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Rutas restantes del sistema
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Iniciar Sesión'),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Registro'),
      ),
      GoRoute(
        path: RouteNames.pagos,
        builder: (context, state) => const _PlaceholderScreen(title: 'Pagos'),
      ),
      GoRoute(
        path: RouteNames.entregas,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Entregas'),
      ),
      GoRoute(
        path: RouteNames.notificaciones,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Notificaciones'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Text('Ruta desconocida: ${state.uri}'),
      ),
    ),
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('Pantalla en desarrollo bajo Clean Architecture'),
          ],
        ),
      ),
    );
  }
}
