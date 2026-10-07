import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_constants.dart';
import 'package:tandea/core/routes/app_router.dart';
import 'package:tandea/core/theme/app_theme.dart';
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
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
