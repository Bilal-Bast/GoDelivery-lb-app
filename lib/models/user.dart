class User {
  final String id;
  final String username;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? accountType;
 
  User({
    required this.id,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.accountType,
  });
 
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      accountType: json['accountType'],
    );
  }
 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'accountType': accountType,
    };
  }
 
  String get fullName => '$firstName $lastName';
  bool get isMerchant => role == 'MERCHANT';
  bool get isDriver => role == 'DRIVER';
  bool get isAdmin => role == 'ADMIN';
}
