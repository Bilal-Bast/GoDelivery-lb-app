import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection.dart';
import '../models/driver_stats.dart';
import '../models/finance.dart';
import '../models/order_status.dart';
import '../models/payment.dart';

/// HTTP client for the existing GoDelivery-lb Express API.
///
/// The backend returns plain arrays, plain objects, and `{data: ...}` envelopes.
/// [_request] normalizes those shapes while preserving top-level metadata.
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.godelivery-lb.com',
  );
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static final Logger _logger = Logger();

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final result = await _request(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
      authenticated: false,
    );
    if (result['success'] == true &&
        result['token'] is String &&
        result['user'] is Map) {
      await _saveSession(
        result['token'] as String,
        Map<String, dynamic>.from(result['user'] as Map),
      );
    }
    return result;
  }

  /// GoDelivery-lb has no refresh-token route. Validate the stored 30-minute
  /// bearer token with the authenticated profile endpoint instead.
  static Future<bool> validateSession() async {
    final result = await _request('GET', '/api/auth/me');
    if (result['success'] != true || result['data'] is! Map) return false;
    final user = Map<String, dynamic>.from(result['data'] as Map);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    return true;
  }

  static Future<bool> refreshToken() => validateSession();

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 100,
    bool currentMerchant = false,
  }) {
    final path = currentMerchant ? '/api/orders/my' : '/api/orders';
    return _request('GET', '$path?page=$page&limit=$limit');
  }

  static Future<Map<String, dynamic>> getOrder(String orderId) =>
      _request('GET', '/api/orders/${Uri.encodeComponent(orderId)}');

  static Future<Map<String, dynamic>> createOrder({
    required String orderId,
    required String merchantUsername,
    required String customerFirstName,
    String? customerLastName,
    required String customerPhone,
    required String district,
    required String city,
    required double total,
    required double deliveryCharge,
    bool isExpress = false,
    String expressNote = '',
  }) async {
    final result = await _request('POST', '/api/orders', body: {
      'id': orderId,
      'm': merchantUsername,
      'c': {
        'f': customerFirstName,
        'l': customerLastName ?? '',
        'p': customerPhone,
        'loc': {'d': district, 'cty': city},
      },
      'pr': {'t': total, 'd': deliveryCharge},
      's': 0,
      'e': isExpress,
      'eN': expressNote,
    });
    if (result['order'] is Map) result['data'] = result['order'];
    return result;
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    final statusNumber = _statusNumber(status);
    if (statusNumber == null) {
      return {'success': false, 'error': 'Unknown order status: $status'};
    }
    final result = await _request(
      'PATCH',
      '/api/orders/${Uri.encodeComponent(orderId)}/status',
      body: {
        's': statusNumber,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    if (result['order'] is Map) result['data'] = result['order'];
    return result;
  }

  static Future<Map<String, dynamic>> getUsers() =>
      _request('GET', '/api/users');
  static Future<Map<String, dynamic>> getDrivers() =>
      _request('GET', '/api/drivers');
  static Future<Map<String, dynamic>> getMerchants() =>
      _request('GET', '/api/merchants');

  static Future<Map<String, dynamic>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    int? status,
    String? merchant,
  }) {
    final query = <String, String>{
      if (startDate != null) 'startDate': _dateOnly(startDate),
      if (endDate != null) 'endDate': _dateOnly(endDate),
      if (status != null) 'status': '$status',
      if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
    };
    return _request(
      'GET',
      Uri(path: '/api/analytics', queryParameters: query.isEmpty ? null : query)
          .toString(),
    );
  }

  static Future<Map<String, dynamic>> getFinanceBalances() =>
      _request('GET', '/api/finance/balances');

  static Future<Map<String, dynamic>> getCollections({
    int page = 1,
    int limit = 100,
    String? driver,
  }) {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (driver != null && driver.isNotEmpty) 'driver': driver,
    };
    return _request(
      'GET',
      Uri(path: '/api/collections', queryParameters: query).toString(),
    );
  }

  static Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int limit = 100,
    String? merchant,
    bool? isAdvance,
  }) {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
      if (isAdvance != null) 'isAdvance': '$isAdvance',
    };
    return _request(
      'GET',
      Uri(path: '/api/payments', queryParameters: query).toString(),
    );
  }

  static Future<Map<String, dynamic>> getLocations() =>
      _request('GET', '/api/locations');

  static Future<Map<String, dynamic>> getDriverOrders() =>
      _request('GET', '/api/drivers/orders');
  static Future<DriverStats> getDriverStats() async {
    final result = await _request('GET', '/api/drivers/stats');
    _throwForFailure(result, 'Failed to load driver statistics.');
    return DriverStats.fromJson(_objectData(result));
  }

  static Future<DriverCollectionPage> getDriverCollections({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _request(
      'GET',
      Uri(
        path: '/api/collections/my',
        queryParameters: {'page': '$page', 'limit': '$limit'},
      ).toString(),
    );
    _throwForFailure(result, 'Failed to load collection history.');
    return DriverCollectionPage.fromJson(result);
  }

  static Future<DriverBalance> getDriverBalance() async {
    final result = await _request('GET', '/api/finance/my-balance');
    _throwForFailure(result, 'Failed to load driver balance.');
    return DriverBalance.fromJson(_objectData(result));
  }

  static Future<MerchantBalance> getMerchantBalance() async {
    final result = await _request('GET', '/api/finance/my-balance');
    _throwForFailure(result, 'Failed to load merchant balance.');
    return MerchantBalance.fromJson(_objectData(result));
  }

  static Future<MerchantPaymentPage> getMerchantPayments({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _request(
      'GET',
      Uri(
        path: '/api/payments/my',
        queryParameters: {'page': '$page', 'limit': '$limit'},
      ).toString(),
    );
    _throwForFailure(result, 'Failed to load payment history.');
    return MerchantPaymentPage.fromJson(result);
  }

  static Future<Map<String, dynamic>> getDistricts() => getLocations();

  static Future<Map<String, dynamic>> getCities(String districtId) async {
    final result = await getLocations();
    if (result['success'] != true || result['data'] is! List) return result;
    final district = (result['data'] as List).whereType<Map>().firstWhere(
          (item) => item['id']?.toString() == districtId,
          orElse: () => <String, dynamic>{},
        );
    return {
      'success': true,
      'data': district['cities'] is List ? district['cities'] : <dynamic>[],
    };
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final token = authenticated ? await _getToken() : null;
      if (authenticated && token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final request = http.Request(method, Uri.parse('$baseUrl$endpoint'))
        ..headers['Accept'] = 'application/json'
        ..headers['Content-Type'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) request.body = jsonEncode(body);

      final streamed =
          await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeBody(response.body);
      _logger.d('$method $endpoint -> ${response.statusCode}');

      if (response.statusCode == 401 && authenticated) await logout();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': _errorMessage(decoded, response.statusCode),
        };
      }

      if (decoded is Map) {
        final result = Map<String, dynamic>.from(decoded);
        result['success'] = true;
        result.putIfAbsent('data', () => Map<String, dynamic>.from(decoded));
        return result;
      }
      return {'success': true, 'data': decoded};
    } catch (error) {
      _logger.e('$method $endpoint failed: $error');
      return {'success': false, 'error': 'Network error: $error'};
    }
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  static String _errorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      return decoded['error']?.toString() ??
          decoded['message']?.toString() ??
          'Request failed ($statusCode)';
    }
    return decoded?.toString() ?? 'Request failed ($statusCode)';
  }

  static void _throwForFailure(
    Map<String, dynamic> result,
    String fallback,
  ) {
    if (result['success'] == true) return;
    throw ApiException(
      result['error']?.toString() ?? fallback,
      statusCode: (result['statusCode'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> _objectData(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is! Map) {
      throw const FormatException('Invalid object response from server.');
    }
    return Map<String, dynamic>.from(data);
  }

  static int? _statusNumber(String status) {
    final normalized = status.trim().toUpperCase().replaceAll(' ', '_');
    const known = {
      'WAREHOUSE',
      'NEW',
      'PICKED_UP',
      'PICKEDUP',
      'DELIVERED',
      'CANCELLED',
      'CANCELED',
      'PAID',
      'COLLECTED',
    };
    if (!known.contains(normalized)) return null;
    return OrderStatusValue.fromBackend(normalized).number;
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static Future<void> _saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.remove(_refreshTokenKey);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return null;
    return Map<String, dynamic>.from(jsonDecode(userData) as Map);
  }

  static Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
