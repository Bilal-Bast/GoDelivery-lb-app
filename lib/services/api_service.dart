import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class ApiService {
  // Update this to your backend URL
  static const String baseUrl = 'https://www.godelivery-lb.com';  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  static final Logger _logger = Logger();

  // ==================== AUTH SERVICES ====================

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      _logger.i('Attempting login for user: $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await _saveTokens(
          data['token'],
          data['refreshToken'],
          jsonEncode(data['user']),
        );
        _logger.i('Login successful');
        return data;
      } else {
        _logger.e('Login failed: ${data['error']}');
        return {
          'success': false,
          'error': data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      _logger.e('Login error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        await logout();
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      _logger.e('Token refresh error: $e');
      await logout();
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    _logger.i('User logged out');
  }

  // ==================== ORDER SERVICES ====================

  static Future<Map<String, dynamic>> getOrders({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      String url = '/api/orders?limit=$limit&offset=$offset';
      if (status != null) url += '&status=$status';
      
      return await _getRequest(url);
    } catch (e) {
      _logger.e('Get orders error: $e');
      return {'success': false, 'error': 'Failed to fetch orders'};
    }
  }

  static Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      return await _getRequest('/api/orders/$orderId');
    } catch (e) {
      _logger.e('Get order error: $e');
      return {'success': false, 'error': 'Failed to fetch order'};
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required String customerFirstName,
    String? customerLastName,
    required String customerPhone,
    required String district,
    required String city,
    required double total,
    required double deliveryCharge,
    bool isExpress = false,
    String expressNote = '',
    String? orderId,
  }) async {
    try {
      return await _postRequest('/api/orders', {
        'id': orderId,
        'customerFirstName': customerFirstName,
        'customerLastName': customerLastName,
        'customerPhone': customerPhone,
        'district': district,
        'city': city,
        'total': total,
        'deliveryCharge': deliveryCharge,
        'isExpress': isExpress,
        'expressNote': expressNote,
      });
    } catch (e) {
      _logger.e('Create order error: $e');
      return {'success': false, 'error': 'Failed to create order'};
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      return await _putRequest('/api/orders/$orderId/status', {'status': status});
    } catch (e) {
      _logger.e('Update order status error: $e');
      return {'success': false, 'error': 'Failed to update order'};
    }
  }

  // ==================== DRIVER SERVICES ====================

  static Future<Map<String, dynamic>> getDriverOrders({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      String url = '/api/driver/orders?limit=$limit&offset=$offset';
      if (status != null) url += '&status=$status';
      
      return await _getRequest(url);
    } catch (e) {
      _logger.e('Get driver orders error: $e');
      return {'success': false, 'error': 'Failed to fetch orders'};
    }
  }

  static Future<Map<String, dynamic>> getDriverCollections({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _getRequest('/api/driver/collections?limit=$limit&offset=$offset');
    } catch (e) {
      _logger.e('Get driver collections error: $e');
      return {'success': false, 'error': 'Failed to fetch collections'};
    }
  }

  // ==================== MERCHANT SERVICES ====================

  static Future<Map<String, dynamic>> getMerchantBalance() async {
    try {
      return await _getRequest('/api/merchant/balance');
    } catch (e) {
      _logger.e('Get merchant balance error: $e');
      return {'success': false, 'error': 'Failed to fetch balance'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantPayments({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _getRequest('/api/merchant/payments?limit=$limit&offset=$offset');
    } catch (e) {
      _logger.e('Get merchant payments error: $e');
      return {'success': false, 'error': 'Failed to fetch payments'};
    }
  }

  // ==================== LOCATION SERVICES ====================

  static Future<Map<String, dynamic>> getDistricts() async {
    try {
      return await _getRequest('/api/locations/districts');
    } catch (e) {
      _logger.e('Get districts error: $e');
      return {'success': false, 'error': 'Failed to fetch districts'};
    }
  }

  static Future<Map<String, dynamic>> getCities(String districtId) async {
    try {
      return await _getRequest('/api/locations/cities/$districtId');
    } catch (e) {
      _logger.e('Get cities error: $e');
      return {'success': false, 'error': 'Failed to fetch cities'};
    }
  }

  // ==================== HELPER METHODS ====================

  static Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        if (await refreshToken()) {
          return _getRequest(endpoint);
        }
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        if (await refreshToken()) {
          return _postRequest(endpoint, body);
        }
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        if (await refreshToken()) {
          return _putRequest(endpoint, body);
        }
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<void> _saveTokens(
    String token,
    String refreshToken,
    String userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userKey, userData);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  static Future<bool> isAuthenticated() async {
    return await _getToken() != null;
  }
}