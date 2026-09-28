import 'package:flutter/foundation.dart';

import '../models/analytics_report.dart';
import '../services/api_service.dart';

class AnalyticsQuery {
  final String preset;
  final String? startDate;
  final String? endDate;
  final String? merchantId;
  final String? driverId;
  final String? district;
  final String? city;

  const AnalyticsQuery(
      {this.preset = 'last30',
      this.startDate,
      this.endDate,
      this.merchantId,
      this.driverId,
      this.district,
      this.city});

  Map<String, String> get parameters => {
        if (startDate != null && endDate != null) ...{
          'startDate': startDate!,
          'endDate': endDate!,
        } else
          'preset': preset,
        if (merchantId != null) 'merchantId': merchantId!,
        if (driverId != null) 'driverId': driverId!,
        if (district != null) 'district': district!,
        if (city != null) 'city': city!,
      };

  bool get hasOrderFilters =>
      merchantId != null ||
      driverId != null ||
      district != null ||
      city != null;
}

class AnalyticsReportProvider extends ChangeNotifier {
  final Future<Map<String, dynamic>> Function(Map<String, String>) _loader;
  AnalyticsReportProvider(
      {Future<Map<String, dynamic>> Function(Map<String, String>)? loader})
      : _loader = loader ?? ApiService.getAnalyticsReport;

  AnalyticsQuery _query = const AnalyticsQuery();
  AnalyticsReport? _report;
  String? _error;
  bool _loading = false;
  int _generation = 0;

  AnalyticsQuery get query => _query;
  AnalyticsReport? get report => _report;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> load([AnalyticsQuery? query]) async {
    if (query != null) {
      _query = query;
      _report = null;
    }
    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _loader(_query.parameters);
      if (generation != _generation) return;
      if (result['success'] != true || result['data'] is! Map) {
        throw ApiException(
            result['error']?.toString() ?? 'Analytics unavailable');
      }
      _report = AnalyticsReport.fromJson(
          Map<String, dynamic>.from(result['data'] as Map));
    } catch (error) {
      if (generation != _generation) return;
      _error = error.toString();
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
