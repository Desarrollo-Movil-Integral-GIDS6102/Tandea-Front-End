import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/routes/app_router.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/theme/app_theme.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/core/widgets/secondary_button.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/auth/presentation/screens/welcome_screen.dart';
import 'package:tandea/features/auth/presentation/widgets/welcome_bottom_panel.dart';
import 'package:tandea/features/auth/presentation/widgets/welcome_feature_chip.dart';
import 'package:tandea/features/auth/presentation/widgets/welcome_header.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/injection/injection.dart';

Widget _buildWelcomeApp() {
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
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    ),
  );
}

void main() {
  setUp(() async {
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('WelcomeScreen Widget Tests', () {
    testWidgets('Renderiza correctamente la sección superior (header, logo, nombre y eslogan)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWelcomeApp());
      AppRouter.router.go(RouteNames.welcome);
      await tester.pumpAndSettle();

      // Verifica WelcomeHeader y sus elementos visuales
      expect(find.byType(WelcomeHeader), findsOneWidget);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      expect(find.text('Tandea'), findsOneWidget);
      expect(find.text('En términos de tandear, ¿Tandeas?'), findsOneWidget);
    });

    testWidgets(
        'Renderiza correctamente el panel inferior con títulos, los 3 chips y los 2 botones',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWelcomeApp());
      AppRouter.router.go(RouteNames.welcome);
      await tester.pumpAndSettle();

      // Verifica WelcomeBottomPanel
      expect(find.byType(WelcomeBottomPanel), findsOneWidget);

      // Título y texto de apoyo
      expect(find.text('Organiza tus tandas y alcanza tus metas'), findsOneWidget);
      expect(
        find.text('Ahorra en comunidad con total transparencia y control en cada ronda.'),
        findsOneWidget,
      );

      // Los tres chips requeridos
      expect(find.byType(WelcomeFeatureChip), findsNWidgets(3));
      expect(find.text('Pagos con evidencia'), findsOneWidget);
      expect(find.text('Doble confirmación'), findsOneWidget);
      expect(find.text('Recordatorios'), findsOneWidget);

      // Botón principal y secundario
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.widgetWithText(PrimaryButton, 'Iniciar sesión'), findsOneWidget);

      expect(find.byType(SecondaryButton), findsOneWidget);
      expect(find.widgetWithText(SecondaryButton, 'Registrarse'), findsOneWidget);
    });

    testWidgets('Botón "Iniciar sesión" navega a la pantalla de login (RouteNames.login)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWelcomeApp());
      AppRouter.router.go(RouteNames.welcome);
      await tester.pumpAndSettle();

      // Presionar el botón Iniciar sesión
      final loginButton = find.widgetWithText(PrimaryButton, 'Iniciar sesión');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verificar que se haya navegado a login
      expect(find.text('Iniciar Sesión'), findsAtLeastNWidgets(1));
    });

    testWidgets('Botón "Registrarse" navega a la pantalla de registro (RouteNames.register)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWelcomeApp());
      AppRouter.router.go(RouteNames.welcome);
      await tester.pumpAndSettle();

      // Presionar el botón Registrarse
      final registerButton = find.widgetWithText(SecondaryButton, 'Registrarse');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verificar que se haya navegado a registro
      expect(find.text('Crear Cuenta'), findsAtLeastNWidgets(1));
    });

    testWidgets('Responsive: se renderiza en pantalla pequeña 360x640 sin overflow',
        (WidgetTester tester) async {
      // Configurar tamaño de pantalla pequeña (360x640)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildWelcomeApp());
      AppRouter.router.go(RouteNames.welcome);
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Tandea'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Registrarse'), findsOneWidget);

      // Sin excepciones de RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('PrimaryButton y SecondaryButton respetan las dimensiones y estilos especificados',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                PrimaryButton(text: 'Principal', onPressed: () {}),
                SecondaryButton(text: 'Secundario', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final primarySize = tester.getSize(find.widgetWithText(PrimaryButton, 'Principal'));
      expect(primarySize.height, 52.0);

      final secondarySize = tester.getSize(find.widgetWithText(SecondaryButton, 'Secundario'));
      expect(secondarySize.height, 52.0);
    });
  });
}
