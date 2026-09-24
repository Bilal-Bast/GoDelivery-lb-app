import 'finance.dart';

class MerchantPayment {
  final String id;
  final String merchantId;
  final String merchantName;
  final int number;
  final double amount;
  final String status;
  final String notes;
  final DateTime createdAt;
  final bool isAdvance;
  final int orderCount;
  final FinanceAccountDisplay? admin;
  final List<SettlementOrder> orders;

  MerchantPayment({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.number,
    required this.amount,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.isAdvance,
    required this.orderCount,
    this.admin,
    this.orders = const [],
  });

  factory MerchantPayment.fromJson(Map<String, dynamic> json) {
    final merchant = json['merchant'] is Map
        ? Map<String, dynamic>.from(json['merchant'] as Map)
        : <String, dynamic>{};
    final firstName = merchant['firstName']?.toString() ?? '';
    final lastName = merchant['lastName']?.toString() ?? '';
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
    return MerchantPayment(
      id: json['id']?.toString() ?? '',
      merchantId: merchant['username']?.toString() ??
          json['merchantId']?.toString() ??
          '',
      merchantName: displayName.isNotEmpty
          ? displayName
          : merchant['username']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isAdvance: json['isAdvance'] == true,
      orderCount: orders.length,
      admin: json['admin'] is Map
          ? FinanceAccountDisplay.fromJson(
              Map<String, dynamic>.from(json['admin'] as Map),
            )
          : null,
      orders: orders,
    );
  }
}

class MerchantPaymentPage {
  final List<MerchantPayment> data;
  final Pagination pagination;

  const MerchantPaymentPage({
    required this.data,
    required this.pagination,
  });

  factory MerchantPaymentPage.fromJson(Map<String, dynamic> json) {
    if (json['data'] is! List || json['pagination'] is! Map) {
      throw const FormatException('Invalid payment history response.');
    }
    return MerchantPaymentPage(
      data: (json['data'] as List)
          .whereType<Map>()
          .map((item) => MerchantPayment.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      pagination: Pagination.fromJson(
        Map<String, dynamic>.from(json['pagination'] as Map),
      ),
    );
  }
}
