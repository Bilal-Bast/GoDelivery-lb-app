class ReportRange {
  final String startDate;
  final String endDate;
  final String previousStartDate;
  final String previousEndDate;
  final String timezone;
  final String basis;

  const ReportRange(this.startDate, this.endDate, this.previousStartDate,
      this.previousEndDate, this.timezone, this.basis);

  factory ReportRange.fromJson(Map<String, dynamic> json) => ReportRange(
      json['startDate']?.toString() ?? '',
      json['endDate']?.toString() ?? '',
      json['previousStartDate']?.toString() ?? '',
      json['previousEndDate']?.toString() ?? '',
      json['timezone']?.toString() ?? 'UTC',
      json['basis']?.toString() ?? '');
}

class MetricComparison {
  final double current;
  final double previous;
  final double change;
  final double? percentChange;
  const MetricComparison(
      this.current, this.previous, this.change, this.percentChange);
  factory MetricComparison.fromJson(Map<String, dynamic> json) =>
      MetricComparison(
          (json['current'] as num?)?.toDouble() ?? 0,
          (json['previous'] as num?)?.toDouble() ?? 0,
          (json['change'] as num?)?.toDouble() ?? 0,
          (json['percentChange'] as num?)?.toDouble());
}

class TrendPoint {
  final String period;
  final int orders;
  final int delivered;
  final int cancelled;
  final double grossUSD;
  const TrendPoint(
      this.period, this.orders, this.delivered, this.cancelled, this.grossUSD);
  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
      json['period']?.toString() ?? '',
      (json['orders'] as num?)?.toInt() ?? 0,
      (json['delivered'] as num?)?.toInt() ?? 0,
      (json['cancelled'] as num?)?.toInt() ?? 0,
      (json['grossOrderValueUSD'] as num?)?.toDouble() ?? 0);
}

class PartyReportRow {
  final String id;
  final String name;
  final String? accountType;
  final int orders;
  final int delivered;
  final int cancelled;
  final int pickedUpStatus;
  final int customerCancellations;
  final int merchantCancellations;
  final double grossUSD;
  final double deliveryChargesUSD;
  final double paymentUSD;
  final double collectionGrossUSD;
  final double driverFeeUSD;
  const PartyReportRow(
      {required this.id,
      required this.name,
      this.accountType,
      required this.orders,
      required this.delivered,
      required this.cancelled,
      required this.pickedUpStatus,
      required this.customerCancellations,
      required this.merchantCancellations,
      required this.grossUSD,
      required this.deliveryChargesUSD,
      required this.paymentUSD,
      required this.collectionGrossUSD,
      required this.driverFeeUSD});
  factory PartyReportRow.fromJson(Map<String, dynamic> json) => PartyReportRow(
      id: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      accountType: json['accountType']?.toString(),
      orders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      delivered: (json['deliveredOrders'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelledOrders'] as num?)?.toInt() ?? 0,
      pickedUpStatus: (json['pickedUpStatusOrders'] as num?)?.toInt() ?? 0,
      customerCancellations:
          (json['customerCancellations'] as num?)?.toInt() ?? 0,
      merchantCancellations:
          (json['merchantCancellations'] as num?)?.toInt() ?? 0,
      grossUSD: (json['grossOrderValueUSD'] as num?)?.toDouble() ?? 0,
      deliveryChargesUSD: (json['deliveryChargesUSD'] as num?)?.toDouble() ?? 0,
      paymentUSD: (json['paymentAmountUSD'] as num?)?.toDouble() ?? 0,
      collectionGrossUSD: (json['collectionGrossUSD'] as num?)?.toDouble() ?? 0,
      driverFeeUSD: (json['collectionDriverFeeUSD'] as num?)?.toDouble() ?? 0);
}

class AnalyticsReport {
  final ReportRange range;
  final Map<String, double> summary;
  final Map<String, MetricComparison> comparison;
  final Map<String, int> statuses;
  final String trendBucket;
  final List<TrendPoint> trend;
  final List<PartyReportRow> merchants;
  final List<PartyReportRow> drivers;
  final List<PartyReportRow> districts;
  final List<PartyReportRow> cities;
  final Map<String, dynamic>? finance;
  final String financeScope;

  const AnalyticsReport(
      {required this.range,
      required this.summary,
      required this.comparison,
      required this.statuses,
      required this.trendBucket,
      required this.trend,
      required this.merchants,
      required this.drivers,
      required this.districts,
      required this.cities,
      required this.finance,
      required this.financeScope});

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
    final trend = Map<String, dynamic>.from(json['trend'] as Map? ?? {});
    final regions = Map<String, dynamic>.from(json['regions'] as Map? ?? {});
    List<PartyReportRow> rows(dynamic raw) => (raw as List? ?? const [])
        .whereType<Map>()
        .map((item) => PartyReportRow.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return AnalyticsReport(
      range: ReportRange.fromJson(
          Map<String, dynamic>.from(json['range'] as Map? ?? {})),
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? {})
          .map((key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0)),
      comparison: Map<String, dynamic>.from(json['comparison'] as Map? ?? {})
          .map((key, value) => MapEntry(
              key,
              MetricComparison.fromJson(
                  Map<String, dynamic>.from(value as Map)))),
      statuses: Map<String, dynamic>.from(
              json['rawStatusDistribution'] as Map? ?? {})
          .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      trendBucket: trend['bucket']?.toString() ?? 'day',
      trend: (trend['points'] as List? ?? const [])
          .whereType<Map>()
          .map((point) => TrendPoint.fromJson(Map<String, dynamic>.from(point)))
          .toList(),
      merchants: rows(json['merchants']),
      drivers: rows(json['drivers']),
      districts: rows(regions['districts']),
      cities: rows(regions['cities']),
      finance: json['finance'] is Map
          ? Map<String, dynamic>.from(json['finance'] as Map)
          : null,
      financeScope: json['financeScope']?.toString() ?? '',
    );
  }

  double value(String key) => summary[key] ?? 0;
}

class StatementReport {
  final String kind;
  final String id;
  final String username;
  final String name;
  final String? accountType;
  final String startDate;
  final String endDate;
  final Map<String, double> summary;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> activity;
  final Map<String, double> activityTotals;

  const StatementReport(
      {required this.kind,
      required this.id,
      required this.username,
      required this.name,
      this.accountType,
      required this.startDate,
      required this.endDate,
      required this.summary,
      required this.orders,
      required this.activity,
      required this.activityTotals});

  factory StatementReport.fromJson(Map<String, dynamic> json) {
    final identity = Map<String, dynamic>.from(json['identity'] as Map? ?? {});
    final range = Map<String, dynamic>.from(json['range'] as Map? ?? {});
    Map<String, double> numbers(dynamic raw) =>
        Map<String, dynamic>.from(raw as Map? ?? {}).map(
            (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0));
    List<Map<String, dynamic>> rows(dynamic raw) => (raw as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return StatementReport(
      kind: json['kind']?.toString() ?? '',
      id: identity['id']?.toString() ?? '',
      username: identity['username']?.toString() ?? '',
      name: identity['name']?.toString() ?? '',
      accountType: identity['accountType']?.toString(),
      startDate: range['startDate']?.toString() ?? '',
      endDate: range['endDate']?.toString() ?? '',
      summary: numbers(json['summary']),
      orders: rows(json['orders']),
      activity: rows(json['activity']),
      activityTotals: numbers(json['activityTotals']),
    );
  }
}
