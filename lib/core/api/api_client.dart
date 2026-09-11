import 'package:dio/dio.dart';

import '../auth/auth_storage.dart';

class ApiClient {
  static const String baseUrl =
      'https://www.godelivery-lb.com/api';

  final Dio dio;
  final AuthStorage _storage;

  ApiClient({
    AuthStorage? storage,
  })  : _storage = storage ?? AuthStorage(),
        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }
}