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
  });

  factory MerchantPayment.fromJson(Map<String, dynamic> json) {
    final merchant = json['merchant'] is Map
        ? Map<String, dynamic>.from(json['merchant'] as Map)
        : <String, dynamic>{};
    final firstName = merchant['firstName']?.toString() ?? '';
    final lastName = merchant['lastName']?.toString() ?? '';
    final displayName = '$firstName $lastName'.trim();
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
      orderCount: (json['orders'] as List?)?.length ?? 0,
    );
  }
}
