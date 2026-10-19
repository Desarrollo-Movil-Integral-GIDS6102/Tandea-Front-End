import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/features/tandas/data/models/tanda_model.dart';

abstract class TandasRemoteDataSource {
  Future<List<TandaModel>> getTandas();
  Future<TandaModel> getTandaById(String id);
  Future<TandaModel> createTanda(Map<String, dynamic> tandaData);
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
}
