class Order {
  final String id;
  final String merchantId;
  final String? driverId;
  final String customerFirstName;
  final String? customerLastName;
  final String customerPhone;
  final String district;
  final String city;
  final double total;
  final double deliveryCharge;
  final String status;
  final DateTime createdAt;
  final DateTime statusUpdatedAt;
  final bool isExpress;
  final String expressNote;
  final User? merchant;
  final User? driver;
 
  Order({
    required this.id,
    required this.merchantId,
    this.driverId,
    required this.customerFirstName,
    this.customerLastName,
    required this.customerPhone,
    required this.district,
    required this.city,
    required this.total,
    required this.deliveryCharge,
    required this.status,
    required this.createdAt,
    required this.statusUpdatedAt,
    this.isExpress = false,
    this.expressNote = '',
    this.merchant,
    this.driver,
  });
 
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      merchantId: json['merchantId'] ?? '',
      driverId: json['driverId'],
      customerFirstName: json['customerFirstName'] ?? '',
      customerLastName: json['customerLastName'],
      customerPhone: json['customerPhone'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      status: json['status'] ?? 'WAREHOUSE',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      statusUpdatedAt: DateTime.tryParse(json['statusUpdatedAt'] ?? '') ?? DateTime.now(),
      isExpress: json['isExpress'] ?? false,
      expressNote: json['expressNote'] ?? '',
      merchant: json['merchant'] != null ? User.fromJson(json['merchant']) : null,
      driver: json['driver'] != null ? User.fromJson(json['driver']) : null,
    );
  }
 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'driverId': driverId,
      'customerFirstName': customerFirstName,
      'customerLastName': customerLastName,
      'customerPhone': customerPhone,
      'district': district,
      'city': city,
      'total': total,
      'deliveryCharge': deliveryCharge,
      'status': status,
      'isExpress': isExpress,
      'expressNote': expressNote,
    };
  }
 
  String get customerName => customerLastName != null
      ? '$customerFirstName $customerLastName'
      : customerFirstName;
 
  double get merchantAmount => total - deliveryCharge;
 
  bool get isPending => status == 'WAREHOUSE' || status == 'NEW';
  bool get isDelivered => status == 'DELIVERED';
  bool get isCanceled => status == 'Canceled';
  bool get isPaid => status == 'Paid';
}