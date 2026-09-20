class DriverCollection {
  final String id;
  final String driverId;
  final String driverName;
  final int number;
  final double amount;
  final double deliveryFee;
  final int orderCount;
  final DateTime createdAt;

  DriverCollection({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.number,
    required this.amount,
    required this.deliveryFee,
    required this.orderCount,
    required this.createdAt,
  });

  factory DriverCollection.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] is Map
        ? Map<String, dynamic>.from(json['driver'] as Map)
        : <String, dynamic>{};
    final firstName = driver['firstName']?.toString() ?? '';
    final lastName = driver['lastName']?.toString() ?? '';
    final displayName = '$firstName $lastName'.trim();
    return DriverCollection(
      id: json['id']?.toString() ?? '',
      driverId:
          driver['username']?.toString() ?? json['driverId']?.toString() ?? '',
      driverName: displayName.isNotEmpty
          ? displayName
          : driver['username']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      orderCount: (json['orders'] as List?)?.length ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
