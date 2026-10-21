import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/services/share_service.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/presentation/screens/compartir_codigo_tanda_screen.dart';

class MockShareService implements ShareService {
  String? lastSharedText;
  String? lastSharedSubject;

  @override
  Future<void> shareText(String text, {String? subject}) async {
    lastSharedText = text;
    lastSharedSubject = subject;
  }
}

void main() {
  late MockShareService mockShareService;

  setUp(() {
    mockShareService = MockShareService();
  });

  group('CompartirCodigoTandaScreen Tests', () {
    const testTanda = TandaEntity(
      id: '15',
      nombre: 'Tanda Navideña 2026',
      monto: 1500.0,
      totalParticipantes: 10,
      periodo: 'quincenal',
      estado: 'PENDIENTE',
      inviteCode: 'TND-9X4K2P',
    );

    testWidgets('renderiza código grande, texto prellenado para WhatsApp y botones de acción', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CompartirCodigoTandaScreen(
            inviteCode: testTanda.inviteCode!,
            tanda: testTanda,
            shareService: mockShareService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica encabezados y código grande
      expect(find.text('Invita a tus participantes'), findsOneWidget);
      expect(find.text('CÓDIGO DE INVITACIÓN'), findsOneWidget);
      expect(find.text('TND-9X4K2P'), findsWidgets);

      // Verifica botón para copiar código
      expect(find.text('Copiar código'), findsOneWidget);

      // Verifica previsualización del mensaje para WhatsApp
      expect(find.text('Texto prellenado para WhatsApp'), findsOneWidget);
      expect(find.textContaining('Tanda Navideña 2026'), findsWidgets);
      expect(find.textContaining(r'$1,500.00 MXN'), findsWidgets);
      expect(find.textContaining('Quincenal'), findsWidgets);
      expect(find.textContaining('TND-9X4K2P'), findsWidgets);

      // Verifica botones de compartir
      expect(find.text('Compartir invitación'), findsOneWidget);
      expect(find.text('Copiar texto de invitación'), findsOneWidget);
    });

    testWidgets('botón "Copiar código" copia al portapapeles y cambia su estado a "¡Código copiado!"', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Interceptar portapapeles en el entorno de pruebas
      String? copiedClipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          copiedClipboardText = args['text'] as String?;
          return null;
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CompartirCodigoTandaScreen(
            inviteCode: 'TND-ABC999',
            nombreTanda: 'Tanda Viaje',
            shareService: mockShareService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final copyButton = find.text('Copiar código');
      await tester.tap(copyButton);
      await tester.pump();

      // Verifica que el portapapeles recibió el código
      expect(copiedClipboardText, equals('TND-ABC999'));

      // Verifica que el botón cambió de estado visual
      expect(find.text('¡Código copiado!'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Avanzar el timer de 3 segundos para limpiar el estado
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('botón "Compartir invitación" invoca share_plus con el texto prellenado para WhatsApp', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CompartirCodigoTandaScreen(
            inviteCode: 'TND-WHATSAPP',
            nombreTanda: 'Tanda Verano',
            monto: 2000.0,
            periodo: 'mensual',
            totalParticipantes: 8,
            shareService: mockShareService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareBtn = find.text('Compartir invitación');
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      // Verifica que ShareService fue invocado
      expect(mockShareService.lastSharedText, isNotNull);
      expect(mockShareService.lastSharedText, contains('Tanda Verano'));
      expect(mockShareService.lastSharedText, contains(r'$2,000.00 MXN'));
      expect(mockShareService.lastSharedText, contains('Mensual'));
      expect(mockShareService.lastSharedText, contains('TND-WHATSAPP'));
      expect(mockShareService.lastSharedText, contains('¿Cómo unirte?'));
      expect(mockShareService.lastSharedSubject, contains('Tanda Verano'));
    });
  });
}
