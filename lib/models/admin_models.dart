class AnalyticsOverview {
  final int totalOrders;
  final double totalRevenue;
  final int ordersToday;
  final int activeDrivers;
  final List<int> statusCounts;

  const AnalyticsOverview({
    required this.totalOrders,
    required this.totalRevenue,
    required this.ordersToday,
    required this.activeDrivers,
    required this.statusCounts,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};
    return AnalyticsOverview(
      totalOrders: (summary['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (summary['totalRevenue'] as num?)?.toDouble() ?? 0,
      ordersToday: (summary['ordersToday'] as num?)?.toInt() ?? 0,
      activeDrivers: (summary['activeDrivers'] as num?)?.toInt() ?? 0,
      statusCounts: (summary['statusCounts'] as List?)
              ?.map((value) => (value as num?)?.toInt() ?? 0)
              .toList() ??
          const [0, 0, 0, 0, 0, 0, 0],
    );
  }
}

class FinancePartyBalance {
  final String username;
  final String name;
  final String? accountType;
  final int orderCount;
  final double balance;
  final double entitled;
  final double paid;
  final double ordersValue;

  const FinancePartyBalance({
    required this.username,
    required this.name,
    this.accountType,
    required this.orderCount,
    required this.balance,
    this.entitled = 0,
    this.paid = 0,
    this.ordersValue = 0,
  });

  factory FinancePartyBalance.merchant(Map<String, dynamic> json) {
    return FinancePartyBalance(
      username: json['merchantUsername']?.toString() ?? '',
      name: json['merchantName']?.toString() ?? '',
      accountType: json['accountType']?.toString(),
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      entitled: (json['entitled'] as num?)?.toDouble() ?? 0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0,
      ordersValue: (json['ordersValue'] as num?)?.toDouble() ?? 0,
    );
  }

  factory FinancePartyBalance.driver(Map<String, dynamic> json) {
    return FinancePartyBalance(
      username: json['driverUsername']?.toString() ?? '',
      name: json['driverName']?.toString() ?? '',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      balance: (json['outstanding'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FinanceOverview {
  final List<FinancePartyBalance> merchants;
  final List<FinancePartyBalance> drivers;
  final double owedToMerchants;
  final double owedByMerchants;
  final double owedByDrivers;

  const FinanceOverview({
    required this.merchants,
    required this.drivers,
    required this.owedToMerchants,
    required this.owedByMerchants,
    required this.owedByDrivers,
  });

  factory FinanceOverview.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] is Map
        ? Map<String, dynamic>.from(json['totals'] as Map)
        : <String, dynamic>{};
    return FinanceOverview(
      merchants: (json['merchants'] as List?)
              ?.whereType<Map>()
              .map((item) => FinancePartyBalance.merchant(
                    Map<String, dynamic>.from(item),
                  ))
              .toList() ??
          const [],
      drivers: (json['drivers'] as List?)
              ?.whereType<Map>()
              .map((item) => FinancePartyBalance.driver(
                    Map<String, dynamic>.from(item),
                  ))
              .toList() ??
          const [],
      owedToMerchants: (totals['owedToMerchants'] as num?)?.toDouble() ?? 0,
      owedByMerchants: (totals['owedByMerchants'] as num?)?.toDouble() ?? 0,
      owedByDrivers: (totals['owedByDrivers'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DriverSummary {
  final String username;
  final String name;

  const DriverSummary({required this.username, required this.name});

  factory DriverSummary.fromJson(Map<String, dynamic> json) => DriverSummary(
        username: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}
