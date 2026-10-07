import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/core/routes/route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.initial,
    routes: [
      GoRoute(
        path: RouteNames.initial,
        builder: (context, state) => const _PlaceholderScreen(title: 'Inicio / Tandas'),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const _PlaceholderScreen(title: 'Iniciar Sesión'),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const _PlaceholderScreen(title: 'Registro'),
      ),
      GoRoute(
        path: RouteNames.tandas,
        builder: (context, state) => const _PlaceholderScreen(title: 'Tandas'),
      ),
      GoRoute(
        path: RouteNames.pagos,
        builder: (context, state) => const _PlaceholderScreen(title: 'Pagos'),
      ),
      GoRoute(
        path: RouteNames.entregas,
        builder: (context, state) => const _PlaceholderScreen(title: 'Entregas'),
      ),
      GoRoute(
        path: RouteNames.notificaciones,
        builder: (context, state) => const _PlaceholderScreen(title: 'Notificaciones'),
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (context, state) => const _PlaceholderScreen(title: 'Panel Administrador'),
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
