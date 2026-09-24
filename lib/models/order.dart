import 'user.dart';
import 'order_status.dart';

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

  final OrderStatusValue statusValue;

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
    required String status,
    required this.createdAt,
    required this.statusUpdatedAt,
    this.isExpress = false,
    this.expressNote = '',
    this.merchant,
    this.driver,
  }) : statusValue = OrderStatusValue.fromBackend(status);

  factory Order.fromJson(Map<String, dynamic> json) {
    final customer = json['c'] is Map
        ? Map<String, dynamic>.from(json['c'])
        : <String, dynamic>{};

    final location = customer['loc'] is Map
        ? Map<String, dynamic>.from(customer['loc'])
        : <String, dynamic>{};

    final pricing = json['pr'] is Map
        ? Map<String, dynamic>.from(json['pr'])
        : <String, dynamic>{};

    final statusNumber = json['s'];

    return Order(
      id: json['id']?.toString() ?? '',

      merchantId: json['m']?.toString() ?? '',

      driverId: json['driver']?.toString(),

      customerFirstName: customer['f']?.toString() ?? '',

      customerLastName: customer['l']?.toString().isNotEmpty == true
          ? customer['l'].toString()
          : null,

      customerPhone: customer['p']?.toString() ?? '',

      district: location['d']?.toString() ?? '',

      city: location['cty']?.toString() ?? '',

      total: (pricing['t'] as num?)?.toDouble() ?? 0,

      deliveryCharge: (pricing['d'] as num?)?.toDouble() ?? 0,

      status: OrderStatusValue.fromBackend(statusNumber).code,

      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),

      statusUpdatedAt: DateTime.tryParse(
            json['statusUpdatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),

      isExpress: json['e'] == true,

      expressNote: json['eN']?.toString() ?? '',

      // Your API currently returns merchant/driver as usernames,
      // not complete User objects, so leave these null for now.
      merchant: null,
      driver: null,
    );
  }

  String get status => statusValue.code;

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

  String get customerName {
    if (customerLastName != null && customerLastName!.isNotEmpty) {
      return '$customerFirstName $customerLastName';
    }

    return customerFirstName;
  }

  double get merchantAmount => total - deliveryCharge;

  bool get isPending => statusValue.isPending;

  bool get isDelivered => statusValue == OrderStatusValue.delivered;

  bool get isCanceled => statusValue == OrderStatusValue.cancelled;

  bool get isPaid => statusValue == OrderStatusValue.paid;
}
