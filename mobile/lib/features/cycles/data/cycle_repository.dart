import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/cycle_model.dart';

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CycleRepository(dio);
});

class CycleRepository {
  final Dio _dio;

  CycleRepository(this._dio);

  String _extractErrorMessage(dynamic data, String fallback) {
    if (data is Map) {
      return data.entries
          .map((e) => '${e.key}: ${e.value is List ? e.value.first : e.value}')
          .join('\n');
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }

  Future<List<MonthCycleModel>> getCycles(int messId) async {
    try {
      final response = await _dio.get('${ApiConstants.messes}$messId/cycles/');
      List listData = [];
      if (response.data is List) {
        listData = response.data;
      } else if (response.data is Map && response.data['results'] is List) {
        listData = response.data['results'];
      }

      return listData
          .map((item) => MonthCycleModel.fromJson(Map<dynamic, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data, 'Failed to load month cycles'));
    }
  }

  Future<MonthCycleModel> createCycle({
    required int messId,
    required String name,
    required String startDate,
    String? endDate,
  }) async {
    try {
      final payload = <String, dynamic>{
        'mess': messId,
        'name': name,
        'start_date': startDate,
        'status': 'ACTIVE',
      };
      if (endDate != null && endDate.isNotEmpty) {
        payload['end_date'] = endDate;
      }

      final response = await _dio.post(
        '${ApiConstants.messes}$messId/cycles/',
        data: payload,
      );
      return MonthCycleModel.fromJson(Map<dynamic, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data, 'Failed to create new cycle'));
    }
  }

  Future<void> settleCycle(int messId, int cycleId) async {
    try {
      await _dio.post('${ApiConstants.messes}$messId/cycles/$cycleId/settle/');
      return;
    } catch (_) {}

    try {
      await _dio.post('${ApiConstants.messes}$messId/cycles/$cycleId/close/');
      return;
    } catch (_) {}

    try {
      await _dio.patch(
        '${ApiConstants.messes}$messId/cycles/$cycleId/',
        data: {'status': 'SETTLED'},
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data, 'Failed to settle cycle'));
    }
  }
}