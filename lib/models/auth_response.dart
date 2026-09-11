class AuthUser {
  final String id;
  final String username;
  final String role;

  AuthUser({
    required this.id,
    required this.username,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class AuthResponse {
  final String token;
  final String role;
  final String username;
  final AuthUser user;

  AuthResponse({
    required this.token,
    required this.role,
    required this.username,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      role: json['role'],
      username: json['username'],
      user: AuthUser.fromJson(json['user']),
    );
  }
}