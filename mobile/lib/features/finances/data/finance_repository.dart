import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/finance_models.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return FinanceRepository(dio);
});

class FinanceRepository {
  final Dio _dio;

  FinanceRepository(this._dio);

  String _extractErrorMessage(dynamic data, String fallback) {
    if (data is Map) {
      return data.entries
          .map((e) => '${e.key}: ${e.value is List ? e.value.first : e.value}')
          .join('\n');
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }

  Future<MonthCycleModel?> getActiveCycle(int messId) async {
    // 1. Try direct active cycle endpoint
    try {
      final response = await _dio.get(ApiConstants.activeCycle(messId));
      if (response.data != null && response.data is Map) {
        return MonthCycleModel.fromJson(Map<dynamic, dynamic>.from(response.data));
      }
    } catch (_) {}

    // 2. Fallback: list cycles and pick the active or first cycle
    try {
      final response = await _dio.get('${ApiConstants.messes}$messId/cycles/');
      List list = [];
      if (response.data is List) {
        list = response.data;
      } else if (response.data is Map && response.data['results'] is List) {
        list = response.data['results'];
      }
      if (list.isNotEmpty) {
        final active = list.firstWhere(
          (c) => c['status'] == 'ACTIVE' || c['is_active'] == true,
          orElse: () => list.first,
        );
        return MonthCycleModel.fromJson(Map<dynamic, dynamic>.from(active));
      }
    } catch (_) {}

    return null;
  }

  Future<BalanceSheetModel> getBalanceSheet(int messId, int cycleId) async {
    try {
      final response = await _dio.get(ApiConstants.balanceSheet(messId, cycleId));
      return BalanceSheetModel.fromJson(Map<dynamic, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Failed to load balance sheet'),
      );
    }
  }

  Future<List<DepositModel>> getDeposits(int messId) async {
    try {
      final response = await _dio.get(ApiConstants.deposits(messId));
      final List list = response.data is List
          ? response.data
          : (response.data['results'] ?? []);
      return list
          .map((j) => DepositModel.fromJson(Map<dynamic, dynamic>.from(j)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Failed to load deposits'),
      );
    }
  }

  Future<void> logDeposit({
    required int messId,
    required double amount,
    required String date,
    String? notes,
    int? cycleId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'date': date,
      };
      if (cycleId != null) {
        payload['cycle'] = cycleId;
        payload['month_cycle'] = cycleId;
      }
      if (notes != null && notes.isNotEmpty) {
        payload['notes'] = notes;
      }

      await _dio.post(
        ApiConstants.deposits(messId),
        data: payload,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Failed to record deposit'),
      );
    }
  }

  Future<List<ExpenseModel>> getExpenses(int messId) async {
    try {
      final response = await _dio.get(ApiConstants.expenses(messId));
      final List list = response.data is List
          ? response.data
          : (response.data['results'] ?? []);
      return list
          .map((j) => ExpenseModel.fromJson(Map<dynamic, dynamic>.from(j)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Failed to load expenses'),
      );
    }
  }

  Future<void> logExpense({
    required int messId,
    required String description,
    required double amount,
    required String date,
    int? cycleId,
    String? category,
  }) async {
    try {
      final payload = <String, dynamic>{
        'description': description,
        'amount': amount,
        'date': date,
        'category': category ?? 'BAZAAR',
      };
      if (cycleId != null) {
        payload['cycle'] = cycleId;
        payload['month_cycle'] = cycleId;
      }

      await _dio.post(
        ApiConstants.expenses(messId),
        data: payload,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Failed to log expense'),
      );
    }
  }
}