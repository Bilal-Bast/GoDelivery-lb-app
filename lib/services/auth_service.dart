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

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN RESPONSE: ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);

      await _storage.saveAuth(
        token: authResponse.token,
        role: authResponse.role,
        username: authResponse.username,
      );

      return authResponse;
    } on DioException catch (e) {
      print('===== LOGIN ERROR =====');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      print('Status: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      print('URL: ${e.requestOptions.uri}');
      print('======================');

      final data = e.response?.data;

      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      throw Exception(
        'Unable to connect to GoDelivery server.',
      );
    } catch (e) {
      print('===== OTHER ERROR =====');
      print(e);
      print('======================');

      throw Exception('Login failed: $e');
    }
  }

  Future<AuthUser> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');

      print('ME STATUS: ${response.statusCode}');
      print('ME RESPONSE: ${response.data}');

      return AuthUser.fromJson(response.data);
    } on DioException catch (e) {
      print('===== GET ME ERROR =====');
      print('Status: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      print('Message: ${e.message}');
      print('========================');

      if (e.response?.statusCode == 401) {
        await _storage.clear();
        throw Exception('Session expired');
      }

      throw Exception('Unable to verify session.');
    }
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}