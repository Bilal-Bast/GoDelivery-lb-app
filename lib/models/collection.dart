import 'finance.dart';

class DriverCollection {
  final String id;
  final String driverId;
  final String driverName;
  final int number;
  final double amount;
  final double deliveryFee;
  final int orderCount;
  final DateTime createdAt;
  final FinanceAccountDisplay? admin;
  final List<SettlementOrder> orders;

  DriverCollection({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.number,
    required this.amount,
    required this.deliveryFee,
    required this.orderCount,
    required this.createdAt,
    this.admin,
    this.orders = const [],
  });

  factory DriverCollection.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] is Map
        ? Map<String, dynamic>.from(json['driver'] as Map)
        : <String, dynamic>{};
    final firstName = driver['firstName']?.toString() ?? '';
    final lastName = driver['lastName']?.toString() ?? '';
    final displayName = '$firstName $lastName'.trim();
    final orders = (json['orders'] as List?)
            ?.whereType<Map>()
            .map((item) => SettlementOrder.fromJson(
                  Map<String, dynamic>.from(
                    item['order'] is Map ? item['order'] as Map : item,
                  ),
                ))
            .toList() ??
        const <SettlementOrder>[];
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
      orderCount: orders.length,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      admin: json['admin'] is Map
          ? FinanceAccountDisplay.fromJson(
              Map<String, dynamic>.from(json['admin'] as Map),
            )
          : null,
      orders: orders,
    );
  }
}

class DriverCollectionPage {
  final List<DriverCollection> data;
  final Pagination pagination;

  const DriverCollectionPage({
    required this.data,
    required this.pagination,
  });

  factory DriverCollectionPage.fromJson(Map<String, dynamic> json) {
    if (json['data'] is! List || json['pagination'] is! Map) {
      throw const FormatException('Invalid collection history response.');
    }
    return DriverCollectionPage(
      data: (json['data'] as List)
          .whereType<Map>()
          .map((item) => DriverCollection.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      pagination: Pagination.fromJson(
        Map<String, dynamic>.from(json['pagination'] as Map),
      ),
    );
  }
}
