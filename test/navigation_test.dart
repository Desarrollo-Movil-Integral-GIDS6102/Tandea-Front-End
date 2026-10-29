import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/routes/app_router.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/auth/domain/entities/user_role.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/injection/injection.dart';

import 'tandas_repository_fake.dart';

void main() {
  setUp(() async {
    if (sl.isRegistered<AuthSessionProvider>()) {
      sl.unregister<AuthSessionProvider>();
    }
    sl.registerLazySingleton<AuthSessionProvider>(() => AuthSessionProvider());
    // Cada pestaña de Mis tandas crea su propio TandasProvider desde sl
    if (!sl.isRegistered<TandasProvider>()) {
      sl.registerFactory<TandasProvider>(
        () => TandasProvider(tandasRepository: TandasRepositoryFake()),
      );
    }
  });

  tearDown(() {
    if (sl.isRegistered<AuthSessionProvider>()) {
      sl.unregister<AuthSessionProvider>();
    }
  });

  testWidgets(
      'Navegación usuario: muestra BottomNavigationBar con Participante y Organizador',
      (WidgetTester tester) async {
    final session = sl<AuthSessionProvider>();
    session.setRole(UserRole.usuario);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: AppRouter.router,
      ),
    );
    AppRouter.router.go(RouteNames.tandasParticipante);
    await tester.pumpAndSettle();

    // Debe mostrar la pestaña por defecto: Participante
    expect(find.text('Mis tandas (participante)'), findsAtLeastNWidgets(1));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Participante'), findsOneWidget);
    expect(find.text('Organizador'), findsOneWidget);

    // Tocar la pestaña Organizador
    await tester.tap(find.text('Organizador'));
    await tester.pumpAndSettle();

    // Debe mostrar la pantalla de Organizador
    expect(find.text('Mis tandas (organizador)'), findsAtLeastNWidgets(1));

    // Regresar a la pestaña Participante
    await tester.tap(find.text('Participante'));
    await tester.pumpAndSettle();

    expect(find.text('Mis tandas (participante)'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'Navegación Admin Global: entra al flujo del Panel Administrador Global',
      (WidgetTester tester) async {
    final session = sl<AuthSessionProvider>();
    session.setRole(UserRole.adminGlobal);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: AppRouter.router,
      ),
    );
    AppRouter.router.go(RouteNames.admin);
    await tester.pumpAndSettle();

    // Debe mostrar el panel de admin y NO el BottomNavigationBar de tandas de usuario
    expect(find.text('Panel Administrador Global'), findsAtLeastNWidgets(1));
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
