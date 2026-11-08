import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_constants.dart';
import 'package:tandea/core/network/server_health_service.dart';
import 'package:tandea/core/routes/app_router.dart';
import 'package:tandea/core/theme/app_theme.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/notificaciones/data/services/push_service.dart';
import 'package:tandea/features/notificaciones/presentation/providers/notificacion_provider.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/crear_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/unirse_tanda_provider.dart';
import 'package:tandea/injection/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Antes de initDependencies: el cliente HTTP toma de aquí la URL del backend
  await dotenv.load(fileName: '.env', isOptional: true);
  // Nombres de meses y días en español para el calendario (table_calendar usa intl)
  await initializeDateFormatting('es_MX');
  await initDependencies();
  await sl<AuthProvider>().checkAuthStatus();

  // Verificación de conectividad en modo debug (kDebugMode)
  if (kDebugMode) {
    final healthService = sl<ServerHealthService>();
    final healthResult = await healthService.checkHealth();
    healthResult.when(
      success: (_) => debugPrint('Backend OK'),
      failure: (failure) =>
          debugPrint('Error al conectar con backend: ${failure.message}'),
    );
  }

  runApp(const MainApp());

  // Después de runApp para que el router ya exista si se abrió desde una notificación
  unawaited(sl<PushService>().iniciar());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: sl<AuthSessionProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<AuthProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<TandasProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<CrearTandaProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<UnirseTandaProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<PagoProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<NotificacionProvider>(),
        ),
      ],

      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        scaffoldMessengerKey: PushService.messengerKey,
        // Textos del sistema (diálogos, selectores, menús) en español de México
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
