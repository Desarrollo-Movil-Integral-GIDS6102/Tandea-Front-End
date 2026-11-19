import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_usuario_entity.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

/// Puerto del repositorio de Administración Global (`FE-ADMIN`).
abstract class AdminRepository {
  /// Consulta las métricas analíticas consolidadas de la plataforma (`GET /admin/metricas`).
  Future<Result<AdminMetricasEntity>> obtenerMetricas();

  /// Busca y filtra usuarios de la plataforma (`GET /admin/usuarios?q=&active=`).
  Future<Result<List<AdminUsuarioEntity>>> buscarUsuarios({
    String? q,
    bool? active,
  });

  /// Suspende un usuario (`PATCH /admin/usuarios/:id/suspender`).
  Future<Result<AdminUsuarioEntity>> suspenderUsuario(
    int idUser, {
    String? motivo,
  });

  /// Lista las tandas de la plataforma para el administrador (`GET /tandas?search=&status=`).
  Future<Result<List<TandaEntity>>> listarTandasAdmin({
    String? search,
    String? status,
  });

  /// Lista las disputas o casos reportados (`GET /admin/disputas?status=&idTanda=`).
  Future<Result<List<AdminDisputaEntity>>> listarDisputas({
    String? status,
    int? idTanda,
  });
}
