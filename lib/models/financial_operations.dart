class SettlementSelectionOrder {
  final String id;
  final String status;
  final String? cancelledBy;
  final double total;
  final double deliveryCharge;
  final double settlementValue;
  final double driverFee;

  const SettlementSelectionOrder({
    required this.id,
    required this.status,
    this.cancelledBy,
    required this.total,
    required this.deliveryCharge,
    required this.settlementValue,
    this.driverFee = 0,
  });

  factory SettlementSelectionOrder.collection(Map<String, dynamic> json) =>
      SettlementSelectionOrder(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        cancelledBy: json['cancelledBy']?.toString(),
        total: (json['total'] as num?)?.toDouble() ?? 0,
        deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0,
        settlementValue: (json['collectionValue'] as num?)?.toDouble() ?? 0,
        driverFee: (json['driverFee'] as num?)?.toDouble() ?? 0,
      );

  factory SettlementSelectionOrder.payment(Map<String, dynamic> json) =>
      SettlementSelectionOrder(
        id: json['id']?.toString() ?? '',
        status: 'COLLECTED',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0,
        settlementValue: (json['payable'] as num?)?.toDouble() ?? 0,
      );
}

class SettlementPreview {
  final int orderCount;
  final double grossAmount;
  final double deductions;
  final double netAmount;
  final List<SettlementSelectionOrder> orders;

  const SettlementPreview({
    required this.orderCount,
    required this.grossAmount,
    required this.deductions,
    required this.netAmount,
    this.orders = const [],
  });

  factory SettlementPreview.collection(Map<String, dynamic> json) =>
      SettlementPreview(
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
        grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0,
        deductions: (json['deliveryFeeTotal'] as num?)?.toDouble() ?? 0,
        netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
        orders: _maps(json['orders'])
            .map(SettlementSelectionOrder.collection)
            .toList(),
      );

  factory SettlementPreview.payment(Map<String, dynamic> json) =>
      SettlementPreview(
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
        grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0,
        deductions: (json['deliveryCharges'] as num?)?.toDouble() ?? 0,
        netAmount: (json['amount'] as num?)?.toDouble() ?? 0,
        orders: _maps(json['orders'])
            .map(SettlementSelectionOrder.payment)
            .toList(),
      );
}

class ReturnableOrder {
  final String id;
  final String customerName;
  final String reason;
  final double goodsValue;
  final bool isExchange;
  final String? cancelledBy;

  const ReturnableOrder({
    required this.id,
    required this.customerName,
    required this.reason,
    required this.goodsValue,
    required this.isExchange,
    this.cancelledBy,
  });

  factory ReturnableOrder.fromJson(Map<String, dynamic> json) =>
      ReturnableOrder(
        id: json['id']?.toString() ?? '',
        customerName: json['customerName']?.toString() ?? '',
        reason: json['reason']?.toString() ?? 'Return',
        goodsValue: (json['goodsValue'] as num?)?.toDouble() ?? 0,
        isExchange: json['isExchange'] == true,
        cancelledBy: json['cancelledBy']?.toString(),
      );
}

class MerchantReturnRecord {
  final String id;
  final int number;
  final String merchantUsername;
  final String adminUsername;
  final double goodsValue;
  final String notes;
  final DateTime createdAt;
  final List<String> orderIds;

  const MerchantReturnRecord({
    required this.id,
    required this.number,
    required this.merchantUsername,
    required this.adminUsername,
    required this.goodsValue,
    required this.notes,
    required this.createdAt,
    required this.orderIds,
  });

  factory MerchantReturnRecord.fromJson(Map<String, dynamic> json) {
    final merchant = json['merchant'] is Map
        ? Map<String, dynamic>.from(json['merchant'] as Map)
        : <String, dynamic>{};
    final admin = json['admin'] is Map
        ? Map<String, dynamic>.from(json['admin'] as Map)
        : <String, dynamic>{};
    return MerchantReturnRecord(
      id: json['id']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      merchantUsername: merchant['username']?.toString() ?? '',
      adminUsername: admin['username']?.toString() ?? '',
      goodsValue: (json['goodsValue'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      orderIds: _maps(json['orders'])
          .map((item) => item['order'] is Map
              ? (item['order'] as Map)['id']?.toString() ?? ''
              : item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }
}

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : const [];
