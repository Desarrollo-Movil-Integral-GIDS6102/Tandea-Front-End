import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/auth/presentation/providers/perfil_provider.dart';
import 'package:tandea/features/auth/presentation/screens/cambiar_password_screen.dart';
import 'package:tandea/features/auth/presentation/screens/perfil_screen.dart';
import 'package:tandea/features/auth/presentation/screens/login_screen.dart';
import 'package:tandea/features/auth/presentation/screens/register_screen.dart';
import 'package:tandea/features/auth/presentation/screens/welcome_screen.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/pagos/presentation/screens/registrar_pago_screen.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/presentation/screens/compartir_codigo_tanda_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/crear_tanda_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/mis_tandas_organizador_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/mis_tandas_participante_screen.dart';
import 'package:tandea/features/tandas/presentation/providers/tanda_detalle_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/features/tandas/presentation/screens/seleccionar_numero_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/tanda_detalle_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/tandas_navigation_screen.dart';
import 'package:tandea/features/tandas/presentation/screens/unirse_tanda_screen.dart';
import 'package:tandea/injection/injection.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.welcome,
    refreshListenable: sl<AuthSessionProvider>(),
    redirect: (context, state) {
      final session = sl<AuthSessionProvider>();
      final loc = state.matchedLocation;

      // Si el usuario ya está autenticado e intenta acceder a login o registro, redirigir
      if (session.isAuthenticated) {
        if (loc == RouteNames.welcome ||
            loc == RouteNames.login ||
            loc == RouteNames.register) {
          return session.isAdminGlobal
              ? RouteNames.admin
              : RouteNames.tandasParticipante;
        }
      }

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
      // Ruta de Bienvenida (Ruta inicial de la aplicación)
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

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
                // Cada pestaña con su propia lista; compartida, una pisaba a la otra
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => sl<TandasProvider>(),
                  child: const MisTandasParticipanteScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.tandasOrganizador,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => sl<TandasProvider>(),
                  child: const MisTandasOrganizadorScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.perfil,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => sl<PerfilProvider>()..cargar(),
                  child: const PerfilScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Crear Tanda
      GoRoute(
        path: RouteNames.crearTanda,
        builder: (context, state) => const CrearTandaScreen(),
      ),

      // Unirse a Tanda
      GoRoute(
        path: RouteNames.unirseTanda,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return UnirseTandaScreen(initialCode: code);
        },
      ),

      // Seleccionar Número en Tanda por Elección
      GoRoute(
        path: RouteNames.seleccionarNumero,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is TandaEntity) {
            return SeleccionarNumeroScreen(tanda: extra);
          }
          return const UnirseTandaScreen();
        },
      ),


      // Cambiar contraseña con código de 6 dígitos enviado por correo
      GoRoute(
        path: RouteNames.cambiarPassword,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => sl<PerfilProvider>(),
          child: CambiarPasswordScreen(correo: state.extra as String?),
        ),
      ),

      // Detalle de Tanda (participante y organizador, solo lectura)
      GoRoute(
        path: RouteNames.tandaDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => sl<TandaDetalleProvider>()..cargar(id),
            child: TandaDetalleScreen(idTanda: id),
          );
        },
      ),

      // Compartir Código de Tanda
      GoRoute(
        path: RouteNames.compartirCodigo,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is TandaEntity) {
            return CompartirCodigoTandaScreen(
              inviteCode: extra.inviteCode ?? '',
              tanda: extra,
            );
          } else if (extra is Map<String, dynamic>) {
            return CompartirCodigoTandaScreen(
              inviteCode: extra['inviteCode'] as String? ?? '',
              nombreTanda: extra['nombreTanda'] as String?,
              monto: (extra['monto'] as num?)?.toDouble(),
              periodo: extra['periodo'] as String?,
              totalParticipantes: (extra['totalParticipantes'] as num?)?.toInt(),
            );
          }
          final code = state.uri.queryParameters['code'] ?? '';
          final nombre = state.uri.queryParameters['nombre'];
          return CompartirCodigoTandaScreen(
            inviteCode: code,
            nombreTanda: nombre,
          );
        },
      ),

      // Flujo del Administrador Global
      GoRoute(
        path: RouteNames.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Rutas de Autenticación
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Registrar Pago (AP-03). Recibe RegistrarPagoArgs por `extra`.
      // Navegar a la pantalla de registrar pago (AP-03 & AP-04)
      GoRoute(
        path: RouteNames.registrarPago,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is RegistrarPagoArgs
              ? extra
              : const RegistrarPagoArgs(
                  nombreTanda: 'Tanda de prueba',
                  idNumber: 1,
                  cuota: 1500,
                  numeroTurno: 1,
                  vuelta: 1,
                );
          return ChangeNotifierProvider<PagoProvider>(
            create: (_) => sl<PagoProvider>(),
            child: RegistrarPagoScreen(args: args),
          );
        },
      ),

      // Rutas restantes del sistema
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


  const _PlaceholderScreen({
    required this.title,

  });

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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Pantalla en desarrollo bajo Clean Architecture',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
