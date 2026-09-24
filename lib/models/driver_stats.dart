class DriverStats {
  final int totalDeliveries;
  final int todaysDeliveries;
  final int activeOrders;

  const DriverStats({
    required this.totalDeliveries,
    required this.todaysDeliveries,
    required this.activeOrders,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      totalDeliveries: _requiredInt(json, 'totalDeliveries'),
      todaysDeliveries: _requiredInt(json, 'todaysDeliveries'),
      activeOrders: _requiredInt(json, 'activeOrders'),
    );
  }
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('Missing numeric $key.');
  return value.toInt();
}
