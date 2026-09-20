class User {
  final String id;
  final String username;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? accountType;
  final String? paymentDay;
  final String? orderIdPrefix;
  final double? deliveryFee;
  final double legacyBalance;
  final Map<String, double> deliveryCharges;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.accountType,
    this.paymentDay,
    this.orderIdPrefix,
    this.deliveryFee,
    this.legacyBalance = 0,
    this.deliveryCharges = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      accountType: json['accountType']?.toString(),
      paymentDay: json['paymentDay']?.toString(),
      orderIdPrefix: json['orderIdPrefix']?.toString(),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      legacyBalance: (json['legacyBalance'] as num?)?.toDouble() ?? 0,
      deliveryCharges: _deliveryCharges(json['deliveryCharges']),
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
      'paymentDay': paymentDay,
      'orderIdPrefix': orderIdPrefix,
      'deliveryFee': deliveryFee,
      'legacyBalance': legacyBalance,
      'deliveryCharges': deliveryCharges,
    };
  }

  String get fullName => '$firstName $lastName';
  bool get isMerchant => role.toLowerCase() == 'merchant';
  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isAdmin => role.toLowerCase() == 'admin';
}

Map<String, double> _deliveryCharges(dynamic value) {
  if (value is! Map) return const {};
  return value.map(
    (key, price) => MapEntry(
      key.toString(),
      price is num ? price.toDouble() : double.tryParse('$price') ?? 0,
    ),
  );
}
