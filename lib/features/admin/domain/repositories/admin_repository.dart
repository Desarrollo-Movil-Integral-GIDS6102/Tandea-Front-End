import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';

/// Puerto del repositorio de Administración Global (`FE-ADMIN`).
abstract class AdminRepository {
  /// Consulta las métricas analíticas consolidadas de la plataforma (`GET /admin/metricas`).
  Future<Result<AdminMetricasEntity>> obtenerMetricas();
}
