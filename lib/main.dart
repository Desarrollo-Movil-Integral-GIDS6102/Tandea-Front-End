import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_constants.dart';
import 'package:tandea/core/routes/app_router.dart';
import 'package:tandea/core/theme/app_theme.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/injection/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MainApp());
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
        ChangeNotifierProvider(
          create: (_) => sl<AuthProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<TandasProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<PagoProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
