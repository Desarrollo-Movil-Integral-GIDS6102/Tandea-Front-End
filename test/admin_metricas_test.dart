import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/admin/data/models/admin_metricas_model.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_detalle_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_usuario_entity.dart';
import 'package:tandea/features/admin/domain/repositories/admin_repository.dart';
import 'package:tandea/features/admin/presentation/providers/admin_provider.dart';
import 'package:tandea/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tandea/features/auth/domain/entities/user_role.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

class FakeAdminRepository implements AdminRepository {
  Result<AdminMetricasEntity> metricasResult;
  int llamadasMetricas = 0;

  FakeAdminRepository({required this.metricasResult});

  @override
  Future<Result<AdminMetricasEntity>> obtenerMetricas() async {
    llamadasMetricas++;
    return metricasResult;
  }

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
      const Error(ServerFailure('No implementado en este fake'));

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

  @override
  Future<Result<AdminDisputaDetalleEntity>> obtenerDetalleDisputa(
    int idDispute,
  ) async =>
      const Error(ServerFailure('No implementado en este fake'));

  @override
  Future<Result<AdminDisputaEntity>> resolverDisputa({
    required int idDispute,
    required String accion,
    required String notas,
  }) async =>
      const Error(ServerFailure('No implementado en este fake'));
}

AdminMetricasEntity _metricasDePrueba() {
  return const AdminMetricasEntity(
    usuarios: ConteoUsuarios(
      total: 128,
      activos: 120,
      suspendidos: 8,
    ),
    tandas: ConteoTandas(
      total: 35,
      pendientes: 5,
      activas: 18,
      finalizadas: 10,
      suspendidas: 2,
      canceladas: 0,
    ),
    montoGestionado: 245800.50,
    disputasPendientes: 4,
    montoPorMes: [
      MontoMensual(mes: '2026-09', monto: 45000, pagos: 30),
      MontoMensual(mes: '2026-10', monto: 85800.50, pagos: 55),
      MontoMensual(mes: '2026-11', monto: 115000, pagos: 78),
    ],
  );
}

void main() {
  group('AdminMetricasModel y AdminProvider (Unit Tests)', () {
    test('AdminMetricasModel.fromJson deserializa el contrato de GET /admin/metricas', () {
      final json = <String, dynamic>{
        'statusCode': 200,
        'data': {
          'usuarios': {'total': 50, 'activos': 47, 'suspendidos': 3},
          'tandas': {
            'total': 12,
            'pendientes': 2,
            'activas': 7,
            'finalizadas': 2,
            'suspendidas': 1,
            'canceladas': 0,
          },
          'montoGestionado': 98500.75,
          'disputasPendientes': 2,
          'montoPorMes': [
            {'mes': '2026-10', 'monto': 40000, 'pagos': 20},
            {'mes': '2026-11', 'monto': 58500.75, 'pagos': 31},
          ],
        },
      };

      final model = AdminMetricasModel.fromJson(json);

      expect(model.usuarios.total, 50);
      expect(model.usuarios.activos, 47);
      expect(model.usuarios.suspendidos, 3);
      expect(model.tandas.total, 12);
      expect(model.tandas.activas, 7);
      expect(model.tandas.pendientes, 2);
      expect(model.tandas.finalizadas, 2);
      expect(model.tandas.suspendidas, 1);
      expect(model.montoGestionado, 98500.75);
      expect(model.disputasPendientes, 2);
      expect(model.montoPorMes.length, 2);
      expect(model.montoPorMes.first.etiquetaMes, 'Oct');
      expect(model.montoPorMes.last.etiquetaMes, 'Nov');
    });

    test('AdminProvider.cargarMetricas actualiza metricas o errorMetricas correctamente', () async {
      final fakeRepo = FakeAdminRepository(
        metricasResult: Success(_metricasDePrueba()),
      );
      final provider = AdminProvider(adminRepository: fakeRepo);

      await provider.cargarMetricas();

      expect(fakeRepo.llamadasMetricas, 1);
      expect(provider.isLoadingMetricas, isFalse);
      expect(provider.errorMetricas, isNull);
      expect(provider.metricas?.usuarios.total, 128);
      expect(provider.metricas?.montoGestionado, 245800.50);

      // Simular fallo
      fakeRepo.metricasResult = const Error(ServerFailure('Fallo del servidor'));
      await provider.cargarMetricas();

      expect(provider.errorMetricas, 'Fallo del servidor');
    });
  });

  group('AdminDashboardScreen (Widget Tests - AP-11)', () {
    testWidgets('carga métricas reales en tarjetas KPI y gráfica fl_chart para admin_global',
        (WidgetTester tester) async {
      final session = AuthSessionProvider()
        ..setSession(token: 'jwt_admin', role: UserRole.adminGlobal);
      final fakeRepo = FakeAdminRepository(
        metricasResult: Success(_metricasDePrueba()),
      );
      final adminProvider = AdminProvider(adminRepository: fakeRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthSessionProvider>.value(value: session),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica llamada al repositorio
      expect(fakeRepo.llamadasMetricas, 1);

      // Verifica tarjetas KPI con datos reales
      expect(find.byKey(const Key('kpi_usuarios_card')), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('120 activos'), findsOneWidget);
      expect(find.text('8 suspendidos'), findsOneWidget);

      expect(find.byKey(const Key('kpi_tandas_card')), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('18 activas'), findsOneWidget);
      expect(find.text('5 pendientes'), findsOneWidget);
      expect(find.text('10 finalizadas'), findsOneWidget);
      expect(find.text('2 suspendidas'), findsOneWidget);

      expect(find.byKey(const Key('kpi_monto_card')), findsOneWidget);
      expect(find.text(r'$245,800.50'), findsOneWidget);

      expect(find.byKey(const Key('kpi_disputas_card')), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Verifica que la gráfica mensual de fl_chart está renderizada con etiquetas
      await tester.ensureVisible(
        find.byKey(const Key('admin_metricas_bar_chart')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Sep'), findsOneWidget);
      expect(find.text('Oct'), findsOneWidget);
      expect(find.text('Nov'), findsOneWidget);
    });

    testWidgets('restringe visibilidad del panel global cuando el rol NO es admin_global',
        (WidgetTester tester) async {
      final session = AuthSessionProvider()
        ..setSession(token: 'jwt_user', role: UserRole.usuario);
      final fakeRepo = FakeAdminRepository(
        metricasResult: Success(_metricasDePrueba()),
      );
      final adminProvider = AdminProvider(adminRepository: fakeRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthSessionProvider>.value(value: session),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No debe consultar métricas ni mostrar tarjetas o gráfica
      expect(fakeRepo.llamadasMetricas, 0);
      expect(find.byKey(const Key('admin_acceso_restringido')), findsOneWidget);
      expect(
        find.text('Acceso exclusivo para Administrador Global'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('kpi_usuarios_card')), findsNothing);
      expect(find.byType(BarChart), findsNothing);
    });
  });
}
