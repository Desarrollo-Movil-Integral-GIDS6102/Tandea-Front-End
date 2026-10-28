import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/theme/app_theme.dart';
import 'package:tandea/features/pagos/presentation/widgets/comprobante_placeholder.dart';

import 'comprobante_fakes.dart';

void main() {
  Widget crearWidget({
    bool requerido = true,
    bool procesando = false,
    bool conComprobante = false,
    VoidCallback? onTomarFoto,
    VoidCallback? onSeleccionarGaleria,
    VoidCallback? onEliminar,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ComprobantePlaceholder(
              requerido: requerido,
              procesando: procesando,
              comprobante: conComprobante ? comprobanteDePrueba : null,
              onTomarFoto: onTomarFoto,
              onSeleccionarGaleria: onSeleccionarGaleria,
              onEliminar: onEliminar,
            ),
          ),
        ),
      ),
    );
  }

  group('ComprobantePlaceholder - Estado Inicial', () {
    testWidgets('muestra botones de Cámara y Galería y etiqueta de obligatorio', (tester) async {
      bool camaraPulsada = false;
      bool galeriaPulsada = false;

      await tester.pumpWidget(
        crearWidget(
          requerido: true,
          onTomarFoto: () => camaraPulsada = true,
          onSeleccionarGaleria: () => galeriaPulsada = true,
        ),
      );

      expect(find.text('Comprobante (obligatorio)'), findsOneWidget);
      expect(find.byKey(const Key('boton_camara')), findsOneWidget);
      expect(find.byKey(const Key('boton_galeria')), findsOneWidget);

      await tester.tap(find.byKey(const Key('boton_camara')));
      expect(camaraPulsada, isTrue);

      await tester.tap(find.byKey(const Key('boton_galeria')));
      expect(galeriaPulsada, isTrue);
    });

    testWidgets('muestra etiqueta de opcional cuando requerido es false', (tester) async {
      await tester.pumpWidget(crearWidget(requerido: false));
      expect(find.text('Comprobante (opcional)'), findsOneWidget);
    });
  });

  group('ComprobantePlaceholder - Estado Procesando', () {
    testWidgets('muestra spinner de carga y mensaje de optimización', (tester) async {
      await tester.pumpWidget(crearWidget(procesando: true));

      expect(find.byKey(const Key('comprobante_cargando')), findsOneWidget);
      expect(find.text('Procesando y optimizando imagen...'), findsOneWidget);
      expect(find.byKey(const Key('boton_camara')), findsNothing);
      expect(find.byKey(const Key('boton_galeria')), findsNothing);
    });
  });

  group('ComprobantePlaceholder - Estado Con Comprobante (Vista previa)', () {
    testWidgets('muestra vista previa, nombre del archivo, badge de tamaño y botones de acción',
        (tester) async {
      bool eliminarPulsado = false;

      await tester.pumpWidget(
        crearWidget(
          conComprobante: true,
          onEliminar: () => eliminarPulsado = true,
        ),
      );

      expect(find.byKey(const Key('preview_comprobante')), findsOneWidget);
      expect(find.text('comprobante_test.jpg'), findsOneWidget);
      expect(find.textContaining('KB'), findsOneWidget);
      expect(find.byKey(const Key('boton_cambiar_comprobante')), findsOneWidget);
      expect(find.byKey(const Key('boton_eliminar_comprobante')), findsOneWidget);

      await tester.tap(find.byKey(const Key('boton_eliminar_comprobante')));
      expect(eliminarPulsado, isTrue);
    });

    testWidgets('presionar "Cambiar" abre modal con opciones de cámara y galería', (tester) async {
      bool camaraPulsada = false;

      await tester.pumpWidget(
        crearWidget(
          conComprobante: true,
          onTomarFoto: () => camaraPulsada = true,
        ),
      );

      await tester.tap(find.byKey(const Key('boton_cambiar_comprobante')));
      await tester.pumpAndSettle();

      expect(find.text('Adjuntar comprobante'), findsOneWidget);
      expect(find.byKey(const Key('opcion_modal_camara')), findsOneWidget);
      expect(find.byKey(const Key('opcion_modal_galeria')), findsOneWidget);

      await tester.tap(find.byKey(const Key('opcion_modal_camara')));
      await tester.pumpAndSettle();

      expect(camaraPulsada, isTrue);
      // El modal se cierra tras la selección
      expect(find.text('Adjuntar comprobante'), findsNothing);
    });
  });
}
