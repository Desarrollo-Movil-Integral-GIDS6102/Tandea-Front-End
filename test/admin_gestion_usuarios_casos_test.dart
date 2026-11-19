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
import 'package:tandea/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tandea/features/auth/domain/entities/user_role.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

class FakeAdminGestionRepository implements AdminRepository {
  List<AdminUsuarioEntity> usuarios = [
    const AdminUsuarioEntity(
      idUser: 10,
      name: 'Carlos',
      lastName: 'Mendoza',
      email: 'carlos@tandea.app',
      role: 'usuario',
      active: true,
    ),
    const AdminUsuarioEntity(
      idUser: 11,
      name: 'Ana',
      lastName: 'López',
      email: 'ana@tandea.app',
      role: 'usuario',
      active: true,
    ),
    const AdminUsuarioEntity(
      idUser: 1,
      name: 'Root',
      lastName: 'Admin',
      email: 'admin@tandea.app',
      role: 'admin_global',
      active: true,
    ),
  ];

  List<TandaEntity> tandas = const [
    TandaEntity(
      id: '101',
      nombre: 'Tanda Ahorro Vecinal',
      monto: 1500,
      totalParticipantes: 10,
      periodo: 'quincenal',
      estado: 'ACTIVA',
      inviteCode: 'VEC101',
    ),
    TandaEntity(
      id: '102',
      nombre: 'Tanda Oficina Norte',
      monto: 2000,
      totalParticipantes: 12,
      periodo: 'mensual',
      estado: 'PENDIENTE',
      inviteCode: 'OFI102',
    ),
  ];

  List<AdminDisputaEntity> disputas = const [
    AdminDisputaEntity(
      idDispute: 501,
      idTanda: 101,
      nombreTanda: 'Tanda Ahorro Vecinal',
      idReporter: 10,
      nombreReporter: 'Carlos Mendoza',
      emailReporter: 'carlos@tandea.app',
      reason: 'El organizador rechazó mi comprobante SPEI válido',
      status: 'ABIERTA',
      idPayment: 9001,
    ),
    AdminDisputaEntity(
      idDispute: 502,
      idTanda: 102,
      nombreTanda: 'Tanda Oficina Norte',
      idReporter: 11,
      nombreReporter: 'Ana López',
      emailReporter: 'ana@tandea.app',
      reason: 'Diferencia en monto entregado del turno 2',
      status: 'EN_REVISION',
      idPayout: 8001,
    ),
  ];

  int llamadasBuscarUsuarios = 0;
  String? ultimoQueryUsuarios;
  int? ultimoIdSuspendido;
  String? ultimoMotivoSuspension;

  @override
  Future<Result<AdminMetricasEntity>> obtenerMetricas() async {
    return const Success(
      AdminMetricasEntity(
        usuarios: ConteoUsuarios(total: 3, activos: 3, suspendidos: 0),
        tandas: ConteoTandas(
          total: 2,
          pendientes: 1,
          activas: 1,
          finalizadas: 0,
          suspendidas: 0,
        ),
        montoGestionado: 45000,
        disputasPendientes: 2,
        montoPorMes: [
          MontoMensual(mes: '2026-11', monto: 45000, pagos: 30),
        ],
      ),
    );
  }

  @override
  Future<Result<List<AdminUsuarioEntity>>> buscarUsuarios({
    String? q,
    bool? active,
  }) async {
    llamadasBuscarUsuarios++;
    ultimoQueryUsuarios = q;
    if (q == null || q.trim().isEmpty) {
      return Success(List<AdminUsuarioEntity>.from(usuarios));
    }
    final termino = q.trim().toLowerCase();
    final filtrados = usuarios
        .where(
          (u) =>
              u.nombreCompleto.toLowerCase().contains(termino) ||
              u.email.toLowerCase().contains(termino),
        )
        .toList();
    return Success(filtrados);
  }

  @override
  Future<Result<AdminUsuarioEntity>> suspenderUsuario(
    int idUser, {
    String? motivo,
  }) async {
    ultimoIdSuspendido = idUser;
    ultimoMotivoSuspension = motivo;
    usuarios = usuarios.map((u) {
      if (u.idUser == idUser) {
        return u.copyWith(active: false);
      }
      return u;
    }).toList();
    final actualizado = usuarios.firstWhere((u) => u.idUser == idUser);
    return Success(actualizado);
  }

  @override
  Future<Result<List<TandaEntity>>> listarTandasAdmin({
    String? search,
    String? status,
  }) async {
    if (search == null || search.trim().isEmpty) {
      return Success(tandas);
    }
    final termino = search.trim().toLowerCase();
    return Success(
      tandas
          .where((t) => t.nombre.toLowerCase().contains(termino))
          .toList(),
    );
  }

  @override
  Future<Result<List<AdminDisputaEntity>>> listarDisputas({
    String? status,
    int? idTanda,
  }) async {
    return Success(disputas);
  }

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

void main() {
  late FakeAdminGestionRepository fakeRepo;
  late AuthSessionProvider sessionProvider;
  late AdminProvider adminProvider;

  setUp(() {
    fakeRepo = FakeAdminGestionRepository();
    sessionProvider = AuthSessionProvider()
      ..setSession(token: 'jwt_admin', role: UserRole.adminGlobal);
    adminProvider = AdminProvider(adminRepository: fakeRepo);
  });

  Widget buildTestApp({void Function(AdminDisputaEntity)? onDisputaSelected}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionProvider>.value(
          value: sessionProvider,
        ),
        ChangeNotifierProvider<AdminProvider>.value(
          value: adminProvider,
        ),
      ],
      child: MaterialApp(
        home: AdminDashboardScreen(onDisputaSelected: onDisputaSelected),
      ),
    );
  }

  group('Gestión de Usuarios, Tandas y Casos (SP-4 FE-ADMIN)', () {
    testWidgets('carga y navega entre las pestañas Usuarios, Tandas y Casos',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Pestaña por defecto: Usuarios
      expect(find.byKey(const Key('tab_admin_usuarios')), findsOneWidget);
      expect(find.byKey(const Key('tab_admin_tandas')), findsOneWidget);
      expect(find.byKey(const Key('tab_admin_casos')), findsOneWidget);

      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('Root Admin'), findsOneWidget);

      // Cambiar a pestaña Tandas
      await tester.tap(find.byKey(const Key('tab_admin_tandas')));
      await tester.pumpAndSettle();

      expect(find.text('Tanda Ahorro Vecinal'), findsOneWidget);
      expect(find.text('Tanda Oficina Norte'), findsOneWidget);

      // Cambiar a pestaña Casos
      AdminDisputaEntity? disputaSeleccionada;
      await tester.pumpWidget(
        buildTestApp(onDisputaSelected: (d) => disputaSeleccionada = d),
      );
      await tester.tap(find.byKey(const Key('tab_admin_casos')));
      await tester.pumpAndSettle();

      expect(
        find.text('El organizador rechazó mi comprobante SPEI válido'),
        findsOneWidget,
      );
      expect(
        find.text('Diferencia en monto entregado del turno 2'),
        findsOneWidget,
      );

      // Al tocar un caso se dispara la navegación al detalle
      await tester.tap(find.byKey(const Key('disputa_item_501')));
      await tester.pumpAndSettle();
      expect(disputaSeleccionada?.idDispute, 501);
    });

    testWidgets(
        'SearchBar aplica debounce de 400 ms antes de filtrar la pestaña activa',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final llamadasIniciales = fakeRepo.llamadasBuscarUsuarios;
      final searchBar = find.byKey(const Key('admin_search_bar'));
      expect(searchBar, findsOneWidget);

      // Escribir término de búsqueda
      await tester.enterText(searchBar, 'Ana');

      // Antes de 400 ms (ej. 200 ms) NO se ha disparado la consulta debounced
      await tester.pump(const Duration(milliseconds: 200));
      expect(fakeRepo.llamadasBuscarUsuarios, llamadasIniciales);

      // Al completar los 400 ms se ejecuta la búsqueda y filtra la lista
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(fakeRepo.llamadasBuscarUsuarios, llamadasIniciales + 1);
      expect(fakeRepo.ultimoQueryUsuarios, 'Ana');
      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('Carlos Mendoza'), findsNothing);
    });

    testWidgets(
        'abre diálogo de confirmación al suspender usuario y actualiza su estado en la lista',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // El usuario Carlos Mendoza (id 10) está Activo y tiene botón Suspender
      final btnSuspenderCarlos =
          find.byKey(const Key('btn_suspender_usuario_10'));
      expect(btnSuspenderCarlos, findsOneWidget);

      // El usuario admin_global (id 1) NO debe tener botón Suspender
      expect(find.byKey(const Key('btn_suspender_usuario_1')), findsNothing);

      // Tocar Suspender abre el diálogo de confirmación
      await tester.tap(btnSuspenderCarlos);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dialog_confirmar_suspension')),
        findsOneWidget,
      );
      expect(find.text('Suspender usuario'), findsOneWidget);

      // Capturar motivo opcional y confirmar suspensión
      await tester.enterText(
        find.byKey(const Key('input_motivo_suspension')),
        'Impago reiterado reportado',
      );
      await tester.tap(find.byKey(const Key('btn_confirmar_suspension')));
      await tester.pumpAndSettle();

      // Verifica llamada al repositorio con ID y motivo
      expect(fakeRepo.ultimoIdSuspendido, 10);
      expect(fakeRepo.ultimoMotivoSuspension, 'Impago reiterado reportado');

      // El botón Suspender desaparece para Carlos y su chip cambia a Suspendido
      expect(find.byKey(const Key('btn_suspender_usuario_10')), findsNothing);
      expect(find.text('Suspendido'), findsOneWidget);
      expect(
        find.text('Usuario Carlos Mendoza suspendido correctamente.'),
        findsOneWidget,
      );
    });
  });
}
