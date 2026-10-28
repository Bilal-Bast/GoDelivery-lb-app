class ScheduleBoardOrder {
  final String id;
  final String status;
  final String customerName;
  final String district;
  final String city;
  final String merchant;
  final String? driver;
  final bool isExpress;
  final DateTime? scheduledWindowStart;
  final DateTime? scheduledWindowEnd;
  final String scheduleState;

  const ScheduleBoardOrder({
    required this.id,
    required this.status,
    required this.customerName,
    required this.district,
    required this.city,
    required this.merchant,
    required this.driver,
    required this.isExpress,
    required this.scheduledWindowStart,
    required this.scheduledWindowEnd,
    required this.scheduleState,
  });

  factory ScheduleBoardOrder.fromJson(Map<String, dynamic> json) =>
      ScheduleBoardOrder(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        customerName:
            '${json['customerFirstName'] ?? ''} ${json['customerLastName'] ?? ''}'
                .trim(),
        district: json['district']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        merchant: json['merchant']?.toString() ?? '',
        driver: json['driver']?.toString(),
        isExpress: json['isExpress'] == true,
        scheduledWindowStart: DateTime.tryParse(
          json['scheduledWindowStart']?.toString() ?? '',
        )?.toUtc(),
        scheduledWindowEnd: DateTime.tryParse(
          json['scheduledWindowEnd']?.toString() ?? '',
        )?.toUtc(),
        scheduleState: json['scheduleState']?.toString() ?? 'UNSCHEDULED',
      );
}

class ScheduleBoardData {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final String timeZone;
  final Map<String, List<ScheduleBoardOrder>> groups;

  const ScheduleBoardData({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.timeZone,
    required this.groups,
  });

  factory ScheduleBoardData.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] is Map
        ? Map<String, dynamic>.from(json['groups'] as Map)
        : <String, dynamic>{};
    return ScheduleBoardData(
      page: _int(json['page'], 1),
      pageSize: _int(json['pageSize'], 50),
      total: _int(json['total']),
      totalPages: _int(json['totalPages'], 1),
      hasPrevious: json['hasPrevious'] == true,
      hasNext: json['hasNext'] == true,
      timeZone: json['timeZone']?.toString() ?? 'Asia/Beirut',
      groups: {
        for (final entry in rawGroups.entries)
          entry.key: (entry.value as List? ?? const [])
              .whereType<Map>()
              .map((item) => ScheduleBoardOrder.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false),
      },
    );
  }
}

int _int(dynamic value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
