import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/theme/app_theme.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/presentation/providers/pago_provider.dart';
import 'package:tandea/features/pagos/presentation/screens/registrar_pago_screen.dart';

import 'pago_fakes.dart';

const _args = RegistrarPagoArgs(
  nombreTanda: 'Tanda Navideña',
  idNumber: 10,
  numeroTurno: 3,
  vuelta: 1,
  cuota: 1500,
);

void main() {
  late FakePagoRepository repository;

  setUp(() {
    repository = FakePagoRepository();
  });

  Future<void> abrirPantalla(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Inicio')),
        ),
        GoRoute(
          path: '/pagos/nuevo',
          builder: (context, state) => ChangeNotifierProvider<PagoProvider>(
            create: (_) => PagoProvider(pagoRepository: repository),
            child: const RegistrarPagoScreen(args: _args),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    unawaited(router.push('/pagos/nuevo'));
    await tester.pumpAndSettle();
  }

  Future<void> adjuntarComprobante(WidgetTester tester) async {
    tester
        .element(find.byType(RegistrarPagoScreen))
        .read<PagoProvider>()
        .seleccionarComprobante(comprobanteDePrueba);
    await tester.pumpAndSettle();
  }

  Finder botonYaPague() => find.descendant(
        of: find.byKey(const Key('boton_ya_pague')),
        matching: find.byType(ElevatedButton),
      );

  testWidgets('muestra el nombre de la tanda, el turno y el monto esperado en MXN', (tester) async {
    await abrirPantalla(tester);

    expect(find.text('Tanda Navideña'), findsOneWidget);
    expect(find.text('Turno #3 · Vuelta 1'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('monto_esperado'))).data,
      r'$1,500.00',
    );
    expect(find.text('Transferencia'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('Híbrido'), findsOneWidget);
    expect(find.text('Ya pagué'), findsOneWidget);
  });

  testWidgets('al elegir Híbrido aparecen los dos campos y al elegir otro método desaparecen',
      (tester) async {
    await abrirPantalla(tester);

    expect(find.byKey(const Key('campo_monto_transferencia')), findsNothing);
    expect(find.byKey(const Key('campo_monto_efectivo')), findsNothing);
    expect(find.byKey(const Key('monto_fijo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('metodo_hibrido')));
    await tester.pumpAndSettle();

    expect(find.text('Monto por transferencia'), findsOneWidget);
    expect(find.text('Monto en efectivo'), findsOneWidget);
    expect(find.byKey(const Key('campo_monto_transferencia')), findsOneWidget);
    expect(find.byKey(const Key('campo_monto_efectivo')), findsOneWidget);
    expect(find.byKey(const Key('monto_fijo')), findsNothing);

    await tester.tap(find.byKey(const Key('metodo_efectivo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo_monto_transferencia')), findsNothing);
    expect(find.byKey(const Key('campo_monto_efectivo')), findsNothing);
    expect(find.text('Comprobante (opcional)'), findsOneWidget);
  });

  testWidgets('transferencia sin comprobante: "Ya pagué" deshabilitado; con foto, vista previa y habilitado',
      (tester) async {
    await abrirPantalla(tester);

    expect(tester.widget<ElevatedButton>(botonYaPague()).onPressed, isNull);

    await adjuntarComprobante(tester);

    expect(find.byKey(const Key('comprobante_vista_previa')), findsOneWidget);
    expect(tester.widget<ElevatedButton>(botonYaPague()).onPressed, isNotNull);
  });

  testWidgets('híbrido: "Ya pagué" solo se habilita cuando la suma coincide con la cuota',
      (tester) async {
    await abrirPantalla(tester);
    await adjuntarComprobante(tester);
    await tester.tap(find.byKey(const Key('metodo_hibrido')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo_monto_transferencia')), '1000');
    await tester.enterText(find.byKey(const Key('campo_monto_efectivo')), '400');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(botonYaPague()).onPressed, isNull);
    expect(find.text(r'Los dos montos deben sumar $1,500.00'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo_monto_efectivo')), '500');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(botonYaPague()).onPressed, isNotNull);
    expect(find.text(r'Los dos montos deben sumar $1,500.00'), findsNothing);
  });

  testWidgets('"Ya pagué" se deshabilita y muestra carga mientras se envía', (tester) async {
    repository.pendiente = Completer<Result<PagoEntity>>();
    await abrirPantalla(tester);
    await adjuntarComprobante(tester);

    expect(tester.widget<ElevatedButton>(botonYaPague()).onPressed, isNotNull);

    await tester.tap(botonYaPague());
    await tester.pump();

    expect(tester.widget<ElevatedButton>(botonYaPague()).onPressed, isNull);
    expect(
      find.descendant(of: botonYaPague(), matching: find.byType(CircularProgressIndicator)),
      findsOneWidget,
    );

    await tester.tap(botonYaPague(), warnIfMissed: false);
    await tester.pump();
    expect(repository.llamadas, hasLength(1));

    repository.pendiente!.complete(const Success(pagoRegistradoDePrueba));
    await tester.pumpAndSettle();

    // Al registrarse, muestra "Pago enviado" y "Entendido" regresa a la pantalla anterior
    expect(find.byKey(const Key('dialogo_pago_enviado')), findsOneWidget);
    expect(find.text('Pago enviado'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrarPagoScreen), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('envía los montos del híbrido capturados en los campos', (tester) async {
    await abrirPantalla(tester);
    await adjuntarComprobante(tester);

    await tester.tap(find.byKey(const Key('metodo_hibrido')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_monto_transferencia')), '1000.50');
    await tester.enterText(find.byKey(const Key('campo_monto_efectivo')), '499.50');
    await tester.pump();
    await tester.tap(botonYaPague());
    await tester.pumpAndSettle();

    final params = repository.ultimaLlamada!;
    expect(params.idNumber, 10);
    expect(params.metodoPago, MetodoPago.hibrido);
    expect(params.transferAmount, 1000.50);
    expect(params.cashAmount, 499.50);
  });

  testWidgets('muestra el error del backend en un banner', (tester) async {
    repository.resultado = const Error(ServerFailure('Ya existe un pago', statusCode: 409));
    await abrirPantalla(tester);
    await adjuntarComprobante(tester);

    await tester.tap(botonYaPague());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('banner_error_pago')), findsOneWidget);
    expect(find.text('Este pago ya fue registrado.'), findsOneWidget);
  });
}
