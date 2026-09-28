import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection.dart';
import '../models/driver_stats.dart';
import '../models/finance.dart';
import '../models/order_status.dart';
import '../models/payment.dart';

Map<String, dynamic> buildCreateOrderPayload({
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
  String? driverUsername,
}) {
  return {
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
    if (driverUsername != null && driverUsername.isNotEmpty)
      'driver': driverUsername,
  };
}

Map<String, dynamic> buildUserPayload({
  required String username,
  required String email,
  String? password,
  required String firstName,
  String lastName = '',
  required String phone,
  double? deliveryFee,
  String? accountType,
  String? paymentDay,
  String? orderIdPrefix,
  Map<String, double>? deliveryCharges,
}) =>
    {
      'username': username,
      'email': email,
      if (password != null) 'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      if (deliveryFee != null) 'deliveryFee': deliveryFee,
      if (accountType != null) 'accountType': accountType.toLowerCase(),
      if (paymentDay != null) 'paymentDay': paymentDay,
      if (orderIdPrefix != null) 'orderIdPrefix': orderIdPrefix,
      if (deliveryCharges != null) 'deliveryCharges': deliveryCharges,
    };

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
    Map<String, String> filters = const {},
  }) {
    final path = currentMerchant ? '/api/orders/my' : '/api/orders';
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      ...filters,
    }).query;
    return _request('GET', '$path?$query');
  }

  static Future<Map<String, dynamic>> previewOrderImport(
          List<Map<String, dynamic>> rows) =>
      _request('POST', '/api/orders/import/preview', body: {'rows': rows});

  static Future<Map<String, dynamic>> createOrderPayload(
          Map<String, dynamic> payload) =>
      _request('POST', '/api/orders', body: payload);

  static Future<List<int>> exportOrderCsv({
    Map<String, String> filters = const {},
    Iterable<String>? selectedIds,
  }) async {
    final token = await _getToken();
    if (token == null) throw const ApiException('Not authenticated');
    final query = Uri(queryParameters: {
      ...filters,
      if (selectedIds != null) 'ids': selectedIds.join(','),
    }).query;
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/export.csv?$query'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw ApiException(
          _errorMessage(_decodeBody(response.body), response.statusCode));
    }
    return response.bodyBytes;
  }

  static Future<List<int>> exportFinanceCsv(String kind) async {
    if (!const {'collections', 'payments', 'returns'}.contains(kind)) {
      throw const ApiException('Unsupported finance export');
    }
    final token = await _getToken();
    if (token == null) throw const ApiException('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/finance/export/$kind.csv'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw ApiException(
          _errorMessage(_decodeBody(response.body), response.statusCode));
    }
    return response.bodyBytes;
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
    String? driverUsername,
  }) async {
    final result = await _request(
      'POST',
      '/api/orders',
      body: buildCreateOrderPayload(
        orderId: orderId,
        merchantUsername: merchantUsername,
        customerFirstName: customerFirstName,
        customerLastName: customerLastName,
        customerPhone: customerPhone,
        district: district,
        city: city,
        total: total,
        deliveryCharge: deliveryCharge,
        isExpress: isExpress,
        expressNote: expressNote,
        driverUsername: driverUsername,
      ),
    );
    if (result['order'] is Map) result['data'] = result['order'];
    return result;
  }

  static Future<Map<String, dynamic>> updateOrder({
    required String orderId,
    required Map<String, dynamic> changes,
  }) async {
    final result = await _request(
      'PUT',
      '/api/orders/${Uri.encodeComponent(orderId)}',
      body: changes,
    );
    if (result['order'] is Map) result['data'] = result['order'];
    return result;
  }

  static Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String cancelledBy,
  }) async {
    final result = await _request(
      'POST',
      '/api/orders/${Uri.encodeComponent(orderId)}/cancel',
      body: {'cancelledBy': cancelledBy},
    );
    if (result['order'] is Map) result['data'] = result['order'];
    return result;
  }

  static Future<Map<String, dynamic>> getOrderHistory(String orderId) =>
      _request(
        'GET',
        '/api/orders/${Uri.encodeComponent(orderId)}/history',
      );

  static Future<Map<String, dynamic>> deleteOrder(String orderId) => _request(
        'DELETE',
        '/api/orders/${Uri.encodeComponent(orderId)}',
      );

  static Future<Map<String, dynamic>> validateOrderId(
    String orderId, {
    String? currentOrderId,
  }) =>
      _request(
        'POST',
        '/api/orders/validate-id',
        authenticated: false,
        body: {
          'orderId': orderId,
          if (currentOrderId != null) 'currentOrderId': currentOrderId,
        },
      );

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

  static Future<Map<String, dynamic>> createUser(
    String role,
    Map<String, dynamic> payload,
  ) {
    final segment = switch (role.toUpperCase()) {
      'ADMIN' => 'add-admin',
      'DRIVER' => 'add-driver',
      'MERCHANT' => 'add-merchant',
      _ => '',
    };
    if (segment.isEmpty) {
      return Future.value({'success': false, 'error': 'Invalid role'});
    }
    return _request('POST', '/api/users/$segment', body: payload);
  }

  static Future<Map<String, dynamic>> updateUser(
          String id, Map<String, dynamic> changes) =>
      _request('PUT', '/api/users/${Uri.encodeComponent(id)}', body: changes);

  static Future<Map<String, dynamic>> updateDriver(
          String id, Map<String, dynamic> changes) =>
      _request('PUT', '/api/users/drivers/${Uri.encodeComponent(id)}',
          body: changes);

  static Future<Map<String, dynamic>> updateMerchant(
          String id, Map<String, dynamic> changes) =>
      _request('PUT', '/api/users/merchants/${Uri.encodeComponent(id)}',
          body: changes);

  static Future<Map<String, dynamic>> updateMerchantLegacyBalance(
          String username, double value) =>
      _request(
        'PUT',
        '/api/finance/prepaid-merchant/${Uri.encodeComponent(username)}/legacy-balance',
        body: {'legacyBalance': value},
      );

  static Future<Map<String, dynamic>> updateUserPassword(
          String id, String password) =>
      _request('PUT', '/api/users/${Uri.encodeComponent(id)}/password',
          body: {'password': password});

  static Future<Map<String, dynamic>> getUserDeletePreview(String id) =>
      _request('GET', '/api/users/${Uri.encodeComponent(id)}/delete-preview');

  static Future<Map<String, dynamic>> deleteUser(String id) =>
      _request('DELETE', '/api/users/${Uri.encodeComponent(id)}');
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

  static Future<Map<String, dynamic>> getAnalyticsReport(
          Map<String, String> filters) =>
      _request(
          'GET',
          Uri(path: '/api/analytics/report', queryParameters: filters)
              .toString());

  static Future<Map<String, dynamic>> getStatement({
    required String kind,
    String? id,
    Map<String, String> filters = const {},
  }) {
    if (!const {'merchant', 'driver'}.contains(kind)) {
      throw const ApiException('Invalid statement kind');
    }
    final path = id == null
        ? '/api/analytics/statements/my'
        : '/api/analytics/statements/$kind/${Uri.encodeComponent(id)}';
    return _request(
        'GET', Uri(path: path, queryParameters: filters).toString());
  }

  static Future<List<int>> downloadAnalyticsCsv(
          Map<String, String> filters, String section) =>
      _downloadReport(Uri(path: '/api/analytics/report', queryParameters: {
        ...filters,
        'section': section,
      }).toString());

  static Future<List<int>> downloadStatement({
    required String kind,
    String? id,
    required String format,
    Map<String, String> filters = const {},
  }) {
    if (!const {'merchant', 'driver'}.contains(kind) ||
        !const {'csv', 'pdf'}.contains(format)) {
      throw const ApiException('Invalid statement export');
    }
    final path = id == null
        ? '/api/analytics/statements/my'
        : '/api/analytics/statements/$kind/${Uri.encodeComponent(id)}';
    return _downloadReport(Uri(path: path, queryParameters: {
      ...filters,
      'format': format,
    }).toString());
  }

  static Future<List<int>> _downloadReport(String path) async {
    final token = await _getToken();
    if (token == null) throw const ApiException('Not authenticated');
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: {
      'Authorization': 'Bearer $token'
    }).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw ApiException(
          _errorMessage(_decodeBody(response.body), response.statusCode));
    }
    return response.bodyBytes;
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

  static Future<Map<String, dynamic>> getEligibleCollectionOrders(
          String driverUsername) =>
      _request(
        'GET',
        Uri(
          path: '/api/collections/eligible',
          queryParameters: {'driver': driverUsername},
        ).toString(),
      );

  static Future<Map<String, dynamic>> previewCollection({
    required String driverUsername,
    required List<String> orderIds,
  }) =>
      _request('POST', '/api/collections/preview', body: {
        'driverUsername': driverUsername,
        'orderIds': orderIds,
      });

  static Future<Map<String, dynamic>> createCollection({
    required String driverUsername,
    required List<String> orderIds,
    String notes = '',
  }) =>
      _request('POST', '/api/collections', body: {
        'driverUsername': driverUsername,
        'orderIds': orderIds,
        'notes': notes,
      });

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

  static Future<Map<String, dynamic>> getEligiblePaymentOrders(
          String merchantUsername) =>
      _request(
        'GET',
        Uri(
          path: '/api/payments/eligible',
          queryParameters: {'merchant': merchantUsername},
        ).toString(),
      );

  static Future<Map<String, dynamic>> previewPayment({
    required String merchantUsername,
    required List<String> orderIds,
  }) =>
      _request('POST', '/api/payments/preview', body: {
        'merchantUsername': merchantUsername,
        'orderIds': orderIds,
      });

  static Future<Map<String, dynamic>> createPayment({
    required String merchantUsername,
    required List<String> orderIds,
    String notes = '',
  }) =>
      _request('POST', '/api/payments', body: {
        'merchantUsername': merchantUsername,
        'orderIds': orderIds,
        'notes': notes,
      });

  static Future<Map<String, dynamic>> createPrepaidAdjustment({
    required String merchantUsername,
    required double amount,
    String notes = '',
  }) =>
      _request('POST', '/api/finance/pay-prepaid-merchant', body: {
        'merchantUsername': merchantUsername,
        'amount': amount,
        'notes': notes,
      });

  static Future<Map<String, dynamic>> getReturns({
    int page = 1,
    int limit = 100,
    String? merchant,
  }) =>
      _request(
        'GET',
        Uri(path: '/api/returns', queryParameters: {
          'page': '$page',
          'limit': '$limit',
          if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
        }).toString(),
      );

  static Future<Map<String, dynamic>> getReturnableOrders(
          String merchantUsername) =>
      _request(
        'GET',
        '/api/returns/merchant/${Uri.encodeComponent(merchantUsername)}/returnable',
      );

  static Future<Map<String, dynamic>> createReturn({
    required String merchantUsername,
    required List<String> orderIds,
    String notes = '',
  }) =>
      _request('POST', '/api/returns', body: {
        'merchantUsername': merchantUsername,
        'orderIds': orderIds,
        'notes': notes,
      });

  static Future<Map<String, dynamic>> getLocations() =>
      _request('GET', '/api/locations');

  static Future<Map<String, dynamic>> addLocation({
    required String district,
    required String cityEn,
    required String cityAr,
  }) =>
      _request('POST', '/api/locations', body: {
        'district': district,
        'cityEn': cityEn,
        'cityAr': cityAr,
      });

  static Future<Map<String, dynamic>> trackOrder(String orderId) => _request(
        'GET',
        '/api/orders/track/${Uri.encodeComponent(orderId)}',
        authenticated: false,
      );

  static Future<Map<String, dynamic>> forgotPassword(String email) => _request(
        'POST',
        '/api/auth/forgot-password',
        authenticated: false,
        body: {'email': email},
      );

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _request(
        'POST',
        '/api/auth/reset-password',
        authenticated: false,
        body: {'token': token, 'newPassword': newPassword},
      );

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _request('PATCH', '/api/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

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
