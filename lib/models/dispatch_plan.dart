class DispatchWorkload {
  final int activeCount;
  final int waitingCount;
  final int warehouseCount;
  final int newCount;
  final int pickedUpCount;
  final int expressActiveCount;
  final int weightedUnits;

  const DispatchWorkload({
    required this.activeCount,
    required this.waitingCount,
    required this.warehouseCount,
    required this.newCount,
    required this.pickedUpCount,
    required this.expressActiveCount,
    required this.weightedUnits,
  });

  factory DispatchWorkload.fromJson(Map<String, dynamic> json) =>
      DispatchWorkload(
        activeCount: _int(json['activeCount']),
        waitingCount: _int(json['waitingCount']),
        warehouseCount: _int(json['warehouseCount']),
        newCount: _int(json['newCount']),
        pickedUpCount: _int(json['pickedUpCount']),
        expressActiveCount: _int(json['expressActiveCount']),
        weightedUnits: _int(json['weightedUnits']),
      );
}

class DispatchDriver {
  final String id;
  final String username;
  final String displayName;
  final DispatchWorkload workload;
  final bool isLive;
  final DateTime? liveUpdatedAt;
  final int? score;
  final List<String> reasons;

  const DispatchDriver({
    required this.id,
    required this.username,
    required this.displayName,
    required this.workload,
    required this.isLive,
    this.liveUpdatedAt,
    this.score,
    this.reasons = const [],
  });

  factory DispatchDriver.fromJson(Map<String, dynamic> json) {
    final live = json['liveTracking'] is Map
        ? Map<String, dynamic>.from(json['liveTracking'] as Map)
        : <String, dynamic>{};
    final workload = json['workload'] is Map
        ? Map<String, dynamic>.from(json['workload'] as Map)
        : <String, dynamic>{};
    return DispatchDriver(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName:
          json['displayName']?.toString() ?? json['username']?.toString() ?? '',
      workload: DispatchWorkload.fromJson(workload),
      isLive: live['isLive'] == true,
      liveUpdatedAt: DateTime.tryParse(live['updatedAt']?.toString() ?? ''),
      score: (json['score'] as num?)?.toInt(),
      reasons: (json['reasons'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }
}

class DispatchRecommendation {
  final DispatchDriver? recommendedDriver;
  final List<DispatchDriver> alternatives;
  final List<String> reasons;

  const DispatchRecommendation({
    required this.recommendedDriver,
    required this.alternatives,
    required this.reasons,
  });

  factory DispatchRecommendation.fromJson(Map<String, dynamic> json) =>
      DispatchRecommendation(
        recommendedDriver: json['recommendedDriver'] is Map
            ? DispatchDriver.fromJson(
                Map<String, dynamic>.from(json['recommendedDriver'] as Map),
              )
            : null,
        alternatives: (json['alternatives'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => DispatchDriver.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
        reasons: (json['reasons'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false),
      );
}

class DispatchOrder {
  final String id;
  final String status;
  final String district;
  final String city;
  final bool isExpress;
  final String merchantName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DispatchDriver? currentDriver;
  final DispatchRecommendation? recommendation;

  const DispatchOrder({
    required this.id,
    required this.status,
    required this.district,
    required this.city,
    required this.isExpress,
    required this.merchantName,
    required this.createdAt,
    required this.updatedAt,
    this.currentDriver,
    this.recommendation,
  });

  factory DispatchOrder.fromJson(Map<String, dynamic> json) {
    final merchant = json['merchant'] is Map
        ? Map<String, dynamic>.from(json['merchant'] as Map)
        : <String, dynamic>{};
    final driver = json['currentDriver'] is Map
        ? Map<String, dynamic>.from(json['currentDriver'] as Map)
        : null;
    final recommendation = json['recommendation'] is Map
        ? Map<String, dynamic>.from(json['recommendation'] as Map)
        : null;
    return DispatchOrder(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      isExpress: json['isExpress'] == true,
      merchantName: merchant['displayName']?.toString() ??
          merchant['username']?.toString() ??
          '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      currentDriver: driver == null ? null : DispatchDriver.fromJson(driver),
      recommendation: recommendation == null
          ? null
          : DispatchRecommendation.fromJson(recommendation),
    );
  }
}

class DispatchCityGroup {
  final String city;
  final int orderCount;
  final int expressCount;
  final List<DispatchOrder> orders;

  const DispatchCityGroup({
    required this.city,
    required this.orderCount,
    required this.expressCount,
    required this.orders,
  });

  factory DispatchCityGroup.fromJson(Map<String, dynamic> json) =>
      DispatchCityGroup(
        city: json['city']?.toString() ?? '',
        orderCount: _int(json['orderCount']),
        expressCount: _int(json['expressCount']),
        orders: (json['orders'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => DispatchOrder.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
      );
}

class DispatchDistrictGroup {
  final String district;
  final List<DispatchCityGroup> cities;

  const DispatchDistrictGroup({required this.district, required this.cities});

  factory DispatchDistrictGroup.fromJson(Map<String, dynamic> json) =>
      DispatchDistrictGroup(
        district: json['district']?.toString() ?? '',
        cities: (json['cities'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => DispatchCityGroup.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
      );
}

class DispatchBoard {
  final int page;
  final int pageSize;
  final int totalOrders;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final bool liveTrackingEnabled;
  final List<DispatchDriver> drivers;
  final List<DispatchDistrictGroup> groups;

  const DispatchBoard({
    required this.page,
    required this.pageSize,
    required this.totalOrders,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.liveTrackingEnabled,
    required this.drivers,
    required this.groups,
  });

  factory DispatchBoard.fromJson(Map<String, dynamic> json) => DispatchBoard(
        page: _int(json['page'], fallback: 1),
        pageSize: _int(json['pageSize'], fallback: 50),
        totalOrders: _int(json['totalOrders']),
        totalPages: _int(json['totalPages'], fallback: 1),
        hasPrevious: json['hasPrevious'] == true,
        hasNext: json['hasNext'] == true,
        liveTrackingEnabled: json['liveTrackingEnabled'] == true,
        drivers: (json['drivers'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => DispatchDriver.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
        groups: (json['groups'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => DispatchDistrictGroup.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
      );
}

class DriverSequenceItem {
  final int sequence;
  final String id;
  final String status;
  final String district;
  final String city;
  final bool isExpress;
  final DateTime createdAt;

  const DriverSequenceItem({
    required this.sequence,
    required this.id,
    required this.status,
    required this.district,
    required this.city,
    required this.isExpress,
    required this.createdAt,
  });

  factory DriverSequenceItem.fromJson(Map<String, dynamic> json) =>
      DriverSequenceItem(
        sequence: _int(json['sequence']),
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        district: json['district']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        isExpress: json['isExpress'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

int _int(dynamic value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
