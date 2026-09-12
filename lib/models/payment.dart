class MerchantPayment {
  final String id;
  final String merchantId;
  final double amount;
  final String status;
  final String notes;
  final DateTime createdAt;
  final bool isAdvance;
 
  MerchantPayment({
    required this.id,
    required this.merchantId,
    required this.amount,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.isAdvance,
  });
 
  factory MerchantPayment.fromJson(Map<String, dynamic> json) {
    return MerchantPayment(
      id: json['id'] ?? '',
      merchantId: json['merchantId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isAdvance: json['isAdvance'] ?? false,
    );
  }
}