import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/mess_model.dart';

final messRepositoryProvider = Provider<MessRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return MessRepository(dio);
});

class MessRepository {
  final Dio _dio;

  MessRepository(this._dio);

  Future<List<MessModel>> getMyMesses() async {
    try {
      final response = await _dio.get(ApiConstants.messes);
      final List data = response.data as List;
      return data.map((json) => MessModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load messes';
      throw Exception(msg);
    }
  }

  Future<MessModel> createMess(String name, String? address) async {
    try {
      final response = await _dio.post(
        ApiConstants.messes,
        data: {
          'name': name,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );
      return MessModel.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to create mess';
      throw Exception(msg);
    }
  }

  Future<MessModel> joinMess(String inviteCode) async {
    try {
      final response = await _dio.post(
        ApiConstants.joinMess,
        data: {'invite_code': inviteCode.trim().toUpperCase()},
      );
      return MessModel.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Invalid or expired invite code';
      throw Exception(msg);
    }
  }
}