import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_storage.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiClient _apiClient;
  final AuthStorage _storage;

  AuthService({
    ApiClient? apiClient,
    AuthStorage? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? AuthStorage();

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      await _storage.saveAuth(
        token: authResponse.token,
        role: authResponse.role,
        username: authResponse.username,
      );

      return authResponse;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      throw Exception(
        'Unable to connect to GoDelivery server.',
      );
    }
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}