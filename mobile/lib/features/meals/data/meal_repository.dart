import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/meal_model.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return MealRepository(dio);
});

class MealRepository {
  final Dio _dio;

  MealRepository(this._dio);

  Future<List<MealModel>> getMeals({
    required int messId,
    String? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        ApiConstants.meals(messId),
        queryParameters: queryParams,
      );

      List listData = [];
      if (response.data is List) {
        listData = response.data;
      } else if (response.data is Map && response.data['results'] is List) {
        listData = response.data['results'];
      }

      return listData
          .map((json) => MealModel.fromJson(Map<dynamic, dynamic>.from(json)))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load meals';
      throw Exception(msg);
    }
  }

  Future<MealModel> logMeal({
    required int messId,
    required String date,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.meals(messId),
        data: {
          'date': date,
          'breakfast': breakfast,
          'lunch': lunch,
          'dinner': dinner,
        },
      );
      return MealModel.fromJson(Map<dynamic, dynamic>.from(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Failed to submit meal entry';
      if (data is Map) {
        msg = data.values.map((v) => v is List ? v.first : v.toString()).join('\n');
      }
      throw Exception(msg);
    }
  }
}