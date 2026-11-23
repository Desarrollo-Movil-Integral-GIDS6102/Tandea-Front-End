import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_detalle_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_usuario_entity.dart';
import 'package:tandea/features/admin/domain/repositories/admin_repository.dart';
import 'package:tandea/features/admin/presentation/providers/admin_provider.dart';
import 'package:tandea/features/admin/presentation/screens/admin_caso_detalle_screen.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

class FakeAdminCasoDetalleRepository implements AdminRepository {
  late AdminDisputaDetalleEntity detalle;
  int? ultimoIdResuelto;
  String? ultimaAccionResolucion;
  String? ultimasNotasResolucion;

  FakeAdminCasoDetalleRepository() {
    final disputa = AdminDisputaEntity(
      idDispute: 701,
      idTanda: 101,
      nombreTanda: 'Tanda Ahorro Vecinal',
      idReporter: 10,
      nombreReporter: 'Carlos Mendoza',
      emailReporter: 'carlos@tandea.app',
      reason: 'El organizador rechazó mi comprobante SPEI de \$1,500.00',
      status: 'ABIERTA',
      idPayment: 9001,
      createdAt: DateTime(2026, 11, 15, 14, 30),
    );

    final pago = PagoEntity(
      idPayment: 9001,
      idNumber: 3,
      metodoPago: MetodoPago.transferencia,
      transferAmount: 1500.0,
      cashAmount: 0.0,
      totalAmount: 1500.0,
      status: 'RECHAZADO',
      confirmedByParticipant: true,
      confirmedByAdmin: false,
      ocrVerified: true,
      ocrDetectedAmount: 1500.0,
      evidenceUrl: 'https://cdn.tandea.app/evidencias/comprobante_9001.jpg',
      rejectionReason: 'Folio ilegible según organizador',
      createdAt: DateTime(2026, 11, 15, 10, 0),
    );

    final bitacora = [
      BitacoraEntradaEntity(
        idLog: 1,
        idUser: 10,
        actionType: 'DISPUTE_OPENED',
        entityType: 'DISPUTE',
        entityId: 701,
        description: 'El participante abrió la disputa #701 sobre el pago #9001',
        createdAt: DateTime(2026, 11, 15, 14, 31),
      ),
    ];

    detalle = AdminDisputaDetalleEntity(
      disputa: disputa,
      pago: pago,
      bitacora: bitacora,
    );
  }

  @override
  Future<Result<AdminDisputaDetalleEntity>> obtenerDetalleDisputa(
    int idDispute,
  ) async {
    return Success(detalle);
  }

  @override
  Future<Result<AdminDisputaEntity>> resolverDisputa({
    required int idDispute,
    required String accion,
    required String notas,
  }) async {
    ultimoIdResuelto = idDispute;
    ultimaAccionResolucion = accion;
    ultimasNotasResolucion = notas;

    final resuelta = detalle.disputa.copyWith(
      status: 'RESUELTA',
      resolutionNotes: notas,
      resolvedAt: DateTime(2026, 11, 16, 9, 0),
    );
    detalle = detalle.copyWith(disputa: resuelta);
    return Success(resuelta);
  }

  @override
  Future<Result<AdminMetricasEntity>> obtenerMetricas() async =>
      const Error(ServerFailure('No usado'));

  @override
  Future<Result<List<AdminUsuarioEntity>>> buscarUsuarios({
    String? q,
    bool? active,
  }) async =>
      const Success([]);

  @override
  Future<Result<AdminUsuarioEntity>> suspenderUsuario(
    int idUser, {
    String? motivo,
  }) async =>
      const Error(ServerFailure('No usado'));

  @override
  Future<Result<List<TandaEntity>>> listarTandasAdmin({
    String? search,
    String? status,
  }) async =>
      const Success([]);

  @override
  Future<Result<List<AdminDisputaEntity>>> listarDisputas({
    String? status,
    int? idTanda,
  }) async =>
      const Success([]);
}

void main() {
  late FakeAdminCasoDetalleRepository fakeRepo;
  late AdminProvider adminProvider;

  setUp(() {
    fakeRepo = FakeAdminCasoDetalleRepository();
    adminProvider = AdminProvider(adminRepository: fakeRepo);
  });

  Widget buildTestApp() {
    return ChangeNotifierProvider<AdminProvider>.value(
      value: adminProvider,
      child: const MaterialApp(
        home: AdminCasoDetalleScreen(idDispute: 701),
      ),
    );
  }

  group('AdminCasoDetalleScreen (SP-4 FE-ADMIN)', () {
    testWidgets(
        'muestra la línea de tiempo con pagos, confirmaciones y evidencias del caso en orden cronológico',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verifica orden cronológico en el modelo de dominio
      final eventos = adminProvider.detalleDisputaActual!.lineaTiempo;
      expect(eventos.length, 5);
      expect(eventos[0].tipo, TipoEventoCaso.pagoEntrega);
      expect(eventos[1].tipo, TipoEventoCaso.confirmacion);
      expect(eventos[2].tipo, TipoEventoCaso.evidencia);
      expect(eventos[3].tipo, TipoEventoCaso.reporte);
      expect(eventos[4].tipo, TipoEventoCaso.auditoria);

      // Verifica renderizado de los eventos en la UI
      expect(find.byKey(const Key('caso_linea_tiempo')), findsOneWidget);
      expect(find.byKey(const Key('timeline_evento_0')), findsOneWidget);
      expect(find.text('Pago registrado (#9001)'), findsOneWidget);

      expect(find.byKey(const Key('timeline_evento_1')), findsOneWidget);
      expect(
        find.text('Confirmaciones y validación del pago'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Confirmado por participante'),
        findsOneWidget,
      );
      expect(find.textContaining('OCR verificado'), findsOneWidget);

      expect(find.byKey(const Key('timeline_evento_2')), findsOneWidget);
      expect(find.text('Comprobante de pago adjunto'), findsOneWidget);
      expect(
        find.text('https://cdn.tandea.app/evidencias/comprobante_9001.jpg'),
        findsOneWidget,
      );

      // Verificar orden visual (Y de pago < Y de confirmación < Y de evidencia)
      final yPago =
          tester.getTopLeft(find.byKey(const Key('timeline_evento_0'))).dy;
      final yConfirmacion =
          tester.getTopLeft(find.byKey(const Key('timeline_evento_1'))).dy;
      final yEvidencia =
          tester.getTopLeft(find.byKey(const Key('timeline_evento_2'))).dy;

      expect(yPago, lessThan(yConfirmacion));
      expect(yConfirmacion, lessThan(yEvidencia));
    });

    testWidgets(
        'botón Resolver caso solo se habilita al elegir una opción (mantener, revertir o suspender) y escribir comentario',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final btnFinder = find.byKey(const Key('btn_resolver_caso'));
      await tester.ensureVisible(btnFinder);
      await tester.pumpAndSettle();

      // 1. Inicialmente: sin opción y sin comentario -> botón deshabilitado
      ElevatedButton btn = tester.widget<ElevatedButton>(btnFinder);
      expect(btn.onPressed, isNull);

      // 2. Solo eligiendo opción ('revertir'), pero con comentario vacío -> sigue deshabilitado
      await tester.tap(find.byKey(const Key('opcion_accion_revertir')));
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(btnFinder);
      expect(btn.onPressed, isNull);

      // 3. Escribiendo solo espacios en blanco -> sigue deshabilitado
      final notasField = find.byKey(const Key('input_notas_resolucion'));
      await tester.enterText(notasField, '   ');
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(btnFinder);
      expect(btn.onPressed, isNull);

      // 4. Si se deselecciona la opción pero hay comentario válido -> deshabilitado
      adminProvider.seleccionarAccionResolucion(null);
      await tester.enterText(
        notasField,
        'Se validó comprobante SPEI con OCR coincidente; se revierte rechazo.',
      );
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(btnFinder);
      expect(btn.onPressed, isNull);

      // 5. Al seleccionar opción válida ('revertir') + comentario no vacío -> SE HABILITA
      await tester.tap(find.byKey(const Key('opcion_accion_revertir')));
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(btnFinder);
      expect(btn.onPressed, isNotNull);

      // 6. Ejecutar resolución y verificar transición a RESUELTA
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      expect(fakeRepo.ultimoIdResuelto, 701);
      expect(fakeRepo.ultimaAccionResolucion, 'revertir');
      expect(
        fakeRepo.ultimasNotasResolucion,
        'Se validó comprobante SPEI con OCR coincidente; se revierte rechazo.',
      );
      expect(find.byKey(const Key('tarjeta_caso_resuelto')), findsOneWidget);
      expect(
        find.text('Caso #701 resuelto correctamente.'),
        findsOneWidget,
      );
    });
  });
}
