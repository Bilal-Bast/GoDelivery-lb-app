class DriverCollection {
  final String id;
  final String driverId;
  final double amount;
  final double deliveryFee;
  final DateTime createdAt;
 
  DriverCollection({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.deliveryFee,
    required this.createdAt,
  });
 
  factory DriverCollection.fromJson(Map<String, dynamic> json) {
    return DriverCollection(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}