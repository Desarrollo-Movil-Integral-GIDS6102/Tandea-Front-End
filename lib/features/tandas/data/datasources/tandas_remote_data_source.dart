import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/features/tandas/data/models/tanda_model.dart';

abstract class TandasRemoteDataSource {
  Future<List<TandaModel>> getTandas();
  Future<List<TandaModel>> getMisTandas({required String rol});
  Future<TandaModel> getTandaById(String id);
  Future<TandaModel> createTanda(Map<String, dynamic> tandaData);
  Future<TandaModel> getTandaByInviteCode(String inviteCode);
  Future<Map<String, dynamic>> joinTanda(Map<String, dynamic> data);
  Future<TandaModel> updateStatus(String id, String status);
}

class TandasRemoteDataSourceImpl implements TandasRemoteDataSource {
  final ApiClient apiClient;

  TandasRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<TandaModel>> getTandas() async {
    try {
      final response = await apiClient.get<dynamic>(ApiConstants.tandasEndpoint);
      final rawData = response.data;
      final List<dynamic> list;
      if (rawData is List<dynamic>) {
        list = rawData;
      } else if (rawData is Map<String, dynamic> && rawData['data'] is List<dynamic>) {
        list = rawData['data'] as List<dynamic>;
      } else {
        list = <dynamic>[];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(TandaModel.fromJson)
          .toList();
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al obtener tandas');
    }
  }

  @override
  Future<List<TandaModel>> getMisTandas({required String rol}) async {
    try {
      final response = await apiClient.get<dynamic>(
        ApiConstants.misTandasEndpoint,
        queryParameters: {'rol': rol},
      );
      final rawData = response.data;
      final List<dynamic> list;
      if (rawData is List<dynamic>) {
        list = rawData;
      } else if (rawData is Map<String, dynamic> && rawData['data'] is List<dynamic>) {
        list = rawData['data'] as List<dynamic>;
      } else {
        list = <dynamic>[];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(TandaModel.fromJson)
          .toList();
    } on DioException {
      // Fallback a /tandas?scope=$scope si el endpoint /mias no estuviera disponible
      final scope = (rol == 'organizador' || rol == 'dueno') ? 'dueno' : 'participante';
      try {
        final fallbackResponse = await apiClient.get<dynamic>(
          ApiConstants.tandasEndpoint,
          queryParameters: {'scope': scope},
        );
        final rawData = fallbackResponse.data;
        final List<dynamic> list;
        if (rawData is List<dynamic>) {
          list = rawData;
        } else if (rawData is Map<String, dynamic> && rawData['data'] is List<dynamic>) {
          list = rawData['data'] as List<dynamic>;
        } else {
          list = <dynamic>[];
        }
        return list
            .whereType<Map<String, dynamic>>()
            .map(TandaModel.fromJson)
            .toList();
      } on DioException catch (fallbackError) {
        NetworkErrorHandler.handleDioException(fallbackError, fallbackMessage: 'Error al obtener mis tandas');
      }
    }
  }

  @override
  Future<TandaModel> getTandaById(String id) async {
    try {
      final response = await apiClient.get<dynamic>('${ApiConstants.tandasEndpoint}/$id');
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final tandaData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return TandaModel.fromJson(tandaData);
      }
      throw const ServerException(message: 'Formato de tanda inválido');
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al obtener detalle de la tanda');
    }
  }

  @override
  Future<TandaModel> createTanda(Map<String, dynamic> tandaData) async {
    try {
      final response = await apiClient.post<dynamic>(
        ApiConstants.tandasEndpoint,
        data: tandaData,
      );
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final created = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return TandaModel.fromJson(created);
      }
      throw const ServerException(message: 'Formato de respuesta inválido al crear tanda');
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al crear tanda');
    }
  }

  @override
  Future<TandaModel> getTandaByInviteCode(String inviteCode) async {
    try {
      final response = await apiClient.get<dynamic>(
        '${ApiConstants.tandasEndpoint}/codigo/$inviteCode',
      );
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final tandaData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return TandaModel.fromJson(tandaData);
      }
      throw const ServerException(message: 'Formato de respuesta inválido al consultar código');
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al consultar código de tanda');
    }
  }

  @override
  Future<Map<String, dynamic>> joinTanda(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post<dynamic>(
        '${ApiConstants.tandasEndpoint}/unirse',
        data: data,
      );
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return rawData;
      }
      throw const ServerException(message: 'Formato de respuesta inválido al unirse a la tanda');
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al unirse a la tanda');
    }
  }

  @override
  Future<TandaModel> updateStatus(String id, String status) async {
    try {
      final response = await apiClient.patch<dynamic>(
        '${ApiConstants.tandasEndpoint}/$id/status',
        data: {'status': status},
      );
      final rawData = response.data;
      if (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>) {
        return TandaModel.fromJson(rawData['data'] as Map<String, dynamic>);
      }
      throw const ServerException(message: 'Formato de respuesta inválido al actualizar la tanda');
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al actualizar la tanda');
    }
  }
}
