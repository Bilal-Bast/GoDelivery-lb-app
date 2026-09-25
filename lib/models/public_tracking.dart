import 'order_status.dart';

class PublicTrackingOrder {
  final String id;
  final OrderStatusValue status;
  final String customerName;
  final String phone;
  final String district;
  final String city;
  final double total;
  final String driver;
  final bool isExpress;
  final DateTime? statusUpdatedAt;

  const PublicTrackingOrder({
    required this.id,
    required this.status,
    required this.customerName,
    required this.phone,
    required this.district,
    required this.city,
    required this.total,
    required this.driver,
    required this.isExpress,
    this.statusUpdatedAt,
  });

  factory PublicTrackingOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['c'] is Map
        ? Map<String, dynamic>.from(json['c'] as Map)
        : <String, dynamic>{};
    final location = customer['loc'] is Map
        ? Map<String, dynamic>.from(customer['loc'] as Map)
        : <String, dynamic>{};
    final pricing = json['pr'] is Map
        ? Map<String, dynamic>.from(json['pr'] as Map)
        : <String, dynamic>{};
    return PublicTrackingOrder(
      id: json['id']?.toString() ?? '',
      status: OrderStatusValue.fromBackend(json['s']),
      customerName: '${customer['f'] ?? ''} ${customer['l'] ?? ''}'.trim(),
      phone: customer['p']?.toString() ?? '',
      district: location['d']?.toString() ?? '',
      city: location['cty']?.toString() ?? '',
      total: (pricing['t'] as num?)?.toDouble() ?? 0,
      driver: json['driver']?.toString() ?? 'Not assigned',
      isExpress: json['isExpress'] == true,
      statusUpdatedAt: DateTime.tryParse(
        json['statusUpdatedAt']?.toString() ?? '',
      ),
    );
  }
}
