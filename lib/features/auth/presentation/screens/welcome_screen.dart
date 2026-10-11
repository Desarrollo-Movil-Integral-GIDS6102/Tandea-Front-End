import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/auth/presentation/widgets/welcome_bottom_panel.dart';
import 'package:tandea/features/auth/presentation/widgets/welcome_header.dart';

/// Pantalla de bienvenida de la aplicación Tandea.
///
/// Cumple con los requerimientos de diseño de [FE-AUTH]:
/// 1. Parte superior (~55% de la altura): fondo degradado de 0F766E a 0D9488,
///    círculo blanco con ícono, nombre "Tandea" grande y negrita, eslogan.
/// 2. Parte inferior: panel F9FAFB con esquinas redondeadas (radio 24) que se superpone al degradado,
///    con título, texto de apoyo, tres chips de características, botón principal
///    "Iniciar sesión" y botón secundario "Registrarse".
/// 3. Accesibilidad: textos y botones con contraste WCAG comprobado.
/// 4. Responsive: LayoutBuilder y SingleChildScrollView para garantizar que no exista
///    overflow en pantallas pequeñas (360x640) ni en pantallas altas.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          // La sección superior ocupa aproximadamente el 55% de la altura disponible
          final headerHeight = screenHeight * 0.55;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Stack(
                children: [
                  // Fondo con degradado que cubre la sección superior
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: headerHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryDark,
                            AppColors.primary,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Contenido vertical
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado con ícono, título y eslogan
                      WelcomeHeader(
                        height: headerHeight,
                      ),

                      // Panel inferior que se superpone 24px sobre el degradado
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: WelcomeBottomPanel(
                          onLoginPressed: () => context.push(RouteNames.login),
                          onRegisterPressed: () => context.push(RouteNames.register),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
