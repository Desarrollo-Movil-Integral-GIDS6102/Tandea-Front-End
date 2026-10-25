import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/presentation/widgets/comprobante_selector.dart';

import 'pago_fakes.dart';

void main() {
  Future<List<ComprobanteArchivo?>> abrir(
    WidgetTester tester,
    Future<ComprobanteArchivo?> Function(ImageSource) seleccionarFoto,
  ) async {
    final elegidos = <ComprobanteArchivo?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComprobanteSelector(
            requerido: true,
            onComprobanteSeleccionado: elegidos.add,
            seleccionarFoto: seleccionarFoto,
          ),
        ),
      ),
    );
    return elegidos;
  }

  testWidgets('"Tomar foto" abre la cámara y entrega el comprobante', (tester) async {
    ImageSource? origen;
    final elegidos = await abrir(tester, (o) async {
      origen = o;
      return comprobanteDePrueba;
    });

    await tester.tap(find.byKey(const Key('comprobante_camara')));
    await tester.pumpAndSettle();

    expect(origen, ImageSource.camera);
    expect(elegidos, [comprobanteDePrueba]);
  });

  testWidgets('rechaza fotos de más de 10 MB con un aviso', (tester) async {
    final grande = ComprobanteArchivo(
      bytes: Uint8List(comprobanteMaxBytes + 1),
      nombre: 'grande.jpg',
      mimeType: 'image/jpeg',
    );
    final elegidos = await abrir(tester, (_) async => grande);

    await tester.tap(find.byKey(const Key('comprobante_galeria')));
    await tester.pumpAndSettle();

    expect(elegidos, isEmpty);
    expect(find.text('La foto supera los 10 MB. Intenta con otra.'), findsOneWidget);
  });
}
