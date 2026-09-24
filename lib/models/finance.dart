class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinanceAccountDisplay {
  final String id;
  final String username;
  final String firstName;
  final String lastName;

  const FinanceAccountDisplay({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  factory FinanceAccountDisplay.fromJson(Map<String, dynamic> json) {
    return FinanceAccountDisplay(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
    );
  }

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : username;
  }
}

class SettlementOrder {
  final String id;
  final double? total;
  final double? deliveryCharge;
  final String? status;
  final DateTime? createdAt;

  const SettlementOrder({
    required this.id,
    this.total,
    this.deliveryCharge,
    this.status,
    this.createdAt,
  });

  factory SettlementOrder.fromJson(Map<String, dynamic> json) {
    return SettlementOrder(
      id: json['id']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble(),
      status: json['status']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class DriverBalance {
  final double gross;
  final double feeTotal;
  final double outstanding;
  final int orderCount;

  const DriverBalance({
    required this.gross,
    required this.feeTotal,
    required this.outstanding,
    required this.orderCount,
  });

  factory DriverBalance.fromJson(Map<String, dynamic> json) {
    if (json['role']?.toString().toLowerCase() != 'driver') {
      throw const FormatException('Expected a driver balance response.');
    }
    return DriverBalance(
      gross: _requiredDouble(json, 'gross'),
      feeTotal: _requiredDouble(json, 'feeTotal'),
      outstanding: _requiredDouble(json, 'outstanding'),
      orderCount: _requiredInt(json, 'orderCount'),
    );
  }
}

class MerchantBalance {
  final String accountType;
  final double entitled;
  final double paid;
  final double balance;
  final int orderCount;

  const MerchantBalance({
    required this.accountType,
    required this.entitled,
    required this.paid,
    required this.balance,
    required this.orderCount,
  });

  factory MerchantBalance.fromJson(Map<String, dynamic> json) {
    if (json['role']?.toString().toLowerCase() != 'merchant') {
      throw const FormatException('Expected a merchant balance response.');
    }
    final accountType = json['accountType']?.toString().toUpperCase();
    if (accountType != 'PREPAID' && accountType != 'POSTPAID') {
      throw const FormatException('Invalid merchant account type.');
    }
    return MerchantBalance(
      accountType: accountType!,
      entitled: _requiredDouble(json, 'entitled'),
      paid: _requiredDouble(json, 'paid'),
      balance: _requiredDouble(json, 'balance'),
      orderCount: _requiredInt(json, 'orderCount'),
    );
  }
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('Missing numeric $key.');
  return value.toDouble();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('Missing numeric $key.');
  return value.toInt();
}
