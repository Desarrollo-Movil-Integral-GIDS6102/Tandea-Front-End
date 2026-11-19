import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/features/admin/data/models/admin_disputa_detalle_model.dart';
import 'package:tandea/features/admin/data/models/admin_disputa_model.dart';
import 'package:tandea/features/admin/data/models/admin_metricas_model.dart';
import 'package:tandea/features/admin/data/models/admin_usuario_model.dart';
import 'package:tandea/features/entregas/domain/entities/entrega_entity.dart';
import 'package:tandea/features/pagos/data/models/pago_model.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/tandas/data/models/tanda_model.dart';

abstract class AdminRemoteDataSource {
  Future<AdminMetricasModel> obtenerMetricas();

  Future<List<AdminUsuarioModel>> buscarUsuarios({
    String? q,
    bool? active,
  });

  Future<AdminUsuarioModel> suspenderUsuario(
    int idUser, {
    String? motivo,
  });

  Future<List<TandaModel>> listarTandasAdmin({
    String? search,
    String? status,
  });

  Future<List<AdminDisputaModel>> listarDisputas({
    String? status,
    int? idTanda,
  });

  Future<AdminDisputaDetalleModel> obtenerDetalleDisputa(int idDispute);

  Future<AdminDisputaModel> resolverDisputa({
    required int idDispute,
    required String accion,
    required String notas,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AdminMetricasModel> obtenerMetricas() async {
    try {
      final response = await apiClient.get<dynamic>(
        ApiConstants.adminMetricasEndpoint,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return AdminMetricasModel.fromJson(raw);
      }
      throw const ServerException(
        message: 'Formato de respuesta inválido al consultar métricas.',
      );
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al obtener las métricas globales',
      );
    }
  }

  @override
  Future<List<AdminUsuarioModel>> buscarUsuarios({
    String? q,
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (q != null && q.trim().isNotEmpty) {
        queryParams['q'] = q.trim();
      }
      if (active != null) {
        queryParams['active'] = active.toString();
      }

      final response = await apiClient.get<dynamic>(
        ApiConstants.adminUsuariosEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final lista = _extraerLista(response.data);
      return lista.map(AdminUsuarioModel.fromJson).toList();
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al consultar la lista de usuarios',
      );
    }
  }

  @override
  Future<AdminUsuarioModel> suspenderUsuario(
    int idUser, {
    String? motivo,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (motivo != null && motivo.trim().isNotEmpty) {
        body['motivo'] = motivo.trim();
      }

      final response = await apiClient.patch<dynamic>(
        ApiConstants.adminSuspenderUsuarioEndpoint(idUser),
        data: body,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : raw;
        return AdminUsuarioModel.fromJson(data);
      }
      throw const ServerException(
        message: 'Formato de respuesta inválido al suspender al usuario.',
      );
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al suspender al usuario',
      );
    }
  }

  @override
  Future<List<TandaModel>> listarTandasAdmin({
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'limit': 50,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }

      final response = await apiClient.get<dynamic>(
        ApiConstants.tandasEndpoint,
        queryParameters: queryParams,
      );
      final lista = _extraerLista(response.data);
      return lista.map(TandaModel.fromJson).toList();
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al consultar las tandas de la plataforma',
      );
    }
  }

  @override
  Future<List<AdminDisputaModel>> listarDisputas({
    String? status,
    int? idTanda,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }
      if (idTanda != null) {
        queryParams['idTanda'] = idTanda;
      }

      final response = await apiClient.get<dynamic>(
        ApiConstants.adminDisputasEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final lista = _extraerLista(response.data);
      return lista.map(AdminDisputaModel.fromJson).toList();
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al consultar los casos y disputas',
      );
    }
  }

  @override
  Future<AdminDisputaDetalleModel> obtenerDetalleDisputa(int idDispute) async {
    try {
      final response = await apiClient.get<dynamic>(
        ApiConstants.adminDisputaDetalleEndpoint(idDispute),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw const ServerException(
          message: 'Formato de respuesta inválido al consultar la disputa.',
        );
      }

      final payload = raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw;

      final idPayment = (payload['idPayment'] as num?)?.toInt();
      final idPayout = (payload['idPayout'] as num?)?.toInt();

      PagoEntity? pago;
      if (idPayment != null && idPayment > 0) {
        try {
          final pagoResp = await apiClient.get<dynamic>(
            '${ApiConstants.pagosEndpoint}/$idPayment',
          );
          final pagoRaw = pagoResp.data;
          if (pagoRaw is Map<String, dynamic>) {
            final pagoData = pagoRaw['data'] is Map<String, dynamic>
                ? pagoRaw['data'] as Map<String, dynamic>
                : pagoRaw;
            pago = PagoModel.fromJson(pagoData).toEntity();
          }
        } catch (_) {
          // Si falla la carga secundaria del pago, se continúa con los datos de la disputa
        }
      }

      EntregaEntity? entrega;
      if (idPayout != null && idPayout > 0) {
        try {
          final entregaResp = await apiClient.get<dynamic>(
            '${ApiConstants.entregasEndpoint}/$idPayout',
          );
          final entregaRaw = entregaResp.data;
          if (entregaRaw is Map<String, dynamic>) {
            final entregaData = entregaRaw['data'] is Map<String, dynamic>
                ? entregaRaw['data'] as Map<String, dynamic>
                : entregaRaw;
            entrega = EntregaEntity.fromJson(entregaData);
          }
        } catch (_) {
          // Si falla la carga secundaria de la entrega, se continúa con los datos de la disputa
        }
      }

      return AdminDisputaDetalleModel.fromJson(
        raw,
        pago: pago,
        entrega: entrega,
      );
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al obtener el detalle del caso',
      );
    }
  }

  @override
  Future<AdminDisputaModel> resolverDisputa({
    required int idDispute,
    required String accion,
    required String notas,
  }) async {
    try {
      final response = await apiClient.patch<dynamic>(
        ApiConstants.adminResolverDisputaEndpoint(idDispute),
        data: <String, dynamic>{
          'accion': accion.trim().toLowerCase(),
          'notas': notas.trim(),
        },
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : raw;
        return AdminDisputaModel.fromJson(data);
      }
      throw const ServerException(
        message: 'Formato de respuesta inválido al resolver la disputa.',
      );
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al resolver el caso',
      );
    }
  }

  List<Map<String, dynamic>> _extraerLista(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    if (raw is Map<String, dynamic> && raw['data'] is List) {
      return (raw['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }
}
