import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      return await getProfile();
    } on DioException catch (e) {
      final message =
          e.response?.data['detail'] ?? 'Login failed. Please check your credentials.';
      throw Exception(message);
    }
  }

  Future<UserModel> register({
    required String email,
    required String fullName,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'full_name': fullName,
          'password': password,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        },
      );

      final accessToken = response.data['tokens']['access'];
      final refreshToken = response.data['tokens']['refresh'];

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      final errors = e.response?.data;
      String errorMsg = 'Registration failed.';
      if (errors is Map) {
        errorMsg = errors.values
            .map((v) => v is List ? v.first : v.toString())
            .join('\n');
      }
      throw Exception(errorMsg);
    }
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    return UserModel.fromJson(response.data);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> hasValidToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }
}