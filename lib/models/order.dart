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

  final DateTime? updatedAt;

  final String? cancelledBy;
  final String? cancelledFromStatus;
  final int collectionCount;
  final int paymentCount;
  final int returnCount;
  final int transactionCount;

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
    this.updatedAt,
    this.cancelledBy,
    this.cancelledFromStatus,
    this.collectionCount = 0,
    this.paymentCount = 0,
    this.returnCount = 0,
    this.transactionCount = 0,
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
    final settlement = json['settlement'] is Map
        ? Map<String, dynamic>.from(json['settlement'] as Map)
        : <String, dynamic>{};

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

      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),

      cancelledBy: json['cancelledBy']?.toString(),

      cancelledFromStatus: json['cancelledFromStatus']?.toString(),

      collectionCount: (settlement['collectionCount'] as num?)?.toInt() ?? 0,

      paymentCount: (settlement['paymentCount'] as num?)?.toInt() ?? 0,

      returnCount: (settlement['returnCount'] as num?)?.toInt() ?? 0,

      transactionCount: (settlement['transactionCount'] as num?)?.toInt() ?? 0,

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

  bool get hasFinancialLinks =>
      collectionCount > 0 ||
      paymentCount > 0 ||
      returnCount > 0 ||
      transactionCount > 0;
}

class OrderHistoryEntry {
  final String id;
  final String actionType;
  final dynamic oldValue;
  final dynamic newValue;
  final String performedBy;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const OrderHistoryEntry({
    required this.id,
    required this.actionType,
    this.oldValue,
    this.newValue,
    required this.performedBy,
    this.metadata = const {},
    required this.createdAt,
  });

  factory OrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderHistoryEntry(
      id: json['id']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? 'update',
      oldValue: json['old_value'],
      newValue: json['new_value'],
      performedBy: json['performed_by']?.toString() ?? 'Unknown',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
