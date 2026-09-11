import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey = 'godelivery_token';
  static const _roleKey = 'godelivery_role';
  static const _usernameKey = 'godelivery_username';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAuth({
    required String token,
    required String role,
    required String username,
  }) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );

    await _storage.write(
      key: _roleKey,
      value: role,
    );

    await _storage.write(
      key: _usernameKey,
      value: username,
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> getRole() async {
    return _storage.read(key: _roleKey);
  }

  Future<String?> getUsername() async {
    return _storage.read(key: _usernameKey);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}