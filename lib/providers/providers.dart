import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/payment.dart';
import '../models/order.dart';
import '../models/collection.dart';
import '../models/district.dart';
import '../models/city.dart';
import '../models/admin_models.dart';

import '../services/api_service.dart';

// ==================== AUTH PROVIDER ====================
enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  AuthStatus _status = AuthStatus.initializing;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitializing => _status == AuthStatus.initializing;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  Future<void> restoreSession({bool refreshAccessToken = true}) async {
    _status = AuthStatus.initializing;
    _currentUser = null;
    _error = null;
    notifyListeners();

    try {
      final hasToken = await ApiService.isAuthenticated();
      final userData = await ApiService.getUserData();

      if (!hasToken || userData == null) {
        await ApiService.logout();
        _status = AuthStatus.unauthenticated;
        return;
      }

      if (refreshAccessToken && !await ApiService.validateSession()) {
        _status = AuthStatus.unauthenticated;
        return;
      }

      _currentUser = User.fromJson(
        await ApiService.getUserData() ?? userData,
      );
      _status = AuthStatus.authenticated;
    } catch (_) {
      await ApiService.logout();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.login(
        username: username,
        password: password,
      );

      if (result['success'] == true && result['user'] is Map) {
        _currentUser = User.fromJson(
          Map<String, dynamic>.from(result['user'] as Map),
        );
        _status = AuthStatus.authenticated;
        return true;
      }

      await ApiService.logout();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _error = result['error']?.toString() ?? 'Login failed';
      return false;
    } catch (e) {
      await ApiService.logout();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _error = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
    }
  }
}

// ==================== ORDER PROVIDER ====================
class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await ApiService.getUserData();
      final result = await ApiService.getOrders(
        currentMerchant: user?['role']?.toString().toLowerCase() == 'merchant',
      );

      if (result['success'] == true) {
        final data = result['data'];

        if (data is List) {
          final orders = data
              .map((o) => Order.fromJson(o as Map<String, dynamic>))
              .toList();
          _orders = status == null
              ? orders
              : orders
                  .where((order) =>
                      order.status.toUpperCase() == status.toUpperCase())
                  .toList();
        } else {
          _orders = [];
          _error = 'Invalid orders data received from server.';
        }
      } else {
        _error = result['error']?.toString() ?? 'Failed to load orders.';
      }
    } catch (e) {
      _error = 'Failed to load orders: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getOrder(orderId);
      final data = result['data'];
      if (result['success'] == true && data is Map) {
        _selectedOrder = Order.fromJson(Map<String, dynamic>.from(data));
      } else {
        _error = result['error']?.toString() ??
            'Invalid order data received from server.';
      }
    } catch (error) {
      _error = 'Failed to load order: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.createOrder(
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
      );
      final data = result['data'];
      if (result['success'] == true && data is Map) {
        _orders.insert(
          0,
          Order.fromJson(Map<String, dynamic>.from(data)),
        );
        return true;
      }
      _error = result['error']?.toString() ??
          'Invalid order data received from server.';
      return false;
    } catch (error) {
      _error = 'Failed to create order: $error';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      final data = result['data'];
      if (result['success'] == true && data is Map) {
        final updatedOrder = Order.fromJson(Map<String, dynamic>.from(data));
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }
        if (_selectedOrder?.id == orderId) {
          _selectedOrder = updatedOrder;
        }
        return true;
      }
      _error = result['error']?.toString() ??
          'Invalid order data received from server.';
      return false;
    } catch (error) {
      _error = 'Failed to update order: $error';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ==================== DRIVER PROVIDER ====================
class DriverProvider extends ChangeNotifier {
  List<Order> _driverOrders = [];
  List<DriverCollection> _collections = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get driverOrders => _driverOrders;
  List<DriverCollection> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDriverOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getDriverOrders();

      if (result['success'] == true && result['data'] is List) {
        final orders = (result['data'] as List)
            .map((item) => Order.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
        _driverOrders = status == null
            ? orders
            : orders
                .where((order) =>
                    order.status.toUpperCase() == status.toUpperCase())
                .toList();
      } else {
        _error = result['error']?.toString() ??
            'Invalid driver orders data received from server.';
      }
    } catch (e) {
      _error = 'Failed to load driver orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCollections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getDriverCollections();

      if (result['success'] == true && result['data'] is List) {
        _collections = (result['data'] as List)
            .map((item) => DriverCollection.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      } else {
        _error = result['error']?.toString() ??
            'Invalid collections data received from server.';
      }
    } catch (e) {
      _error = 'Failed to load collections: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      if (result['success'] == true && result['data'] is Map) {
        final updated = Order.fromJson(
          Map<String, dynamic>.from(result['data'] as Map),
        );
        final index = _driverOrders.indexWhere((order) => order.id == orderId);
        if (index != -1) _driverOrders[index] = updated;
        return true;
      }
      _error = result['error']?.toString() ?? 'Failed to update order.';
      return false;
    } catch (error) {
      _error = 'Failed to update order: $error';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ==================== ADMIN PROVIDER ====================
class AdminProvider extends ChangeNotifier {
  AnalyticsOverview? _analytics;
  FinanceOverview? _finance;
  List<User> _users = [];
  List<DriverSummary> _drivers = [];
  List<DriverCollection> _collections = [];
  List<MerchantPayment> _payments = [];
  List<District> _locations = [];
  bool _isLoading = false;
  String? _error;

  AnalyticsOverview? get analytics => _analytics;
  FinanceOverview? get finance => _finance;
  List<User> get users => _users;
  List<DriverSummary> get drivers => _drivers;
  List<DriverCollection> get collections => _collections;
  List<MerchantPayment> get payments => _payments;
  List<District> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    await _load(() async {
      final results = await Future.wait([
        ApiService.getAnalytics(),
        ApiService.getFinanceBalances(),
      ]);
      _requireSuccess(results);
      _analytics = AnalyticsOverview.fromJson(_mapData(results[0]));
      _finance = FinanceOverview.fromJson(_mapData(results[1]));
    });
  }

  Future<void> loadUsers() async {
    await _load(() async {
      final result = await ApiService.getUsers();
      _requireSuccess([result]);
      _users = _listData(result)
          .whereType<Map>()
          .map((item) => User.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> loadDrivers() async {
    await _load(() async {
      final result = await ApiService.getDrivers();
      _requireSuccess([result]);
      _drivers = _listData(result)
          .whereType<Map>()
          .map(
              (item) => DriverSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> loadFinance() async {
    await _load(() async {
      final results = await Future.wait([
        ApiService.getFinanceBalances(),
        ApiService.getCollections(),
        ApiService.getPayments(),
      ]);
      _requireSuccess(results);
      _finance = FinanceOverview.fromJson(_mapData(results[0]));
      _collections = _listData(results[1])
          .whereType<Map>()
          .map((item) =>
              DriverCollection.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _payments = _listData(results[2])
          .whereType<Map>()
          .map((item) =>
              MerchantPayment.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> loadAnalytics() async {
    await _load(() async {
      final result = await ApiService.getAnalytics();
      _requireSuccess([result]);
      _analytics = AnalyticsOverview.fromJson(_mapData(result));
    });
  }

  Future<void> loadLocations() async {
    await _load(() async {
      final result = await ApiService.getLocations();
      _requireSuccess([result]);
      _locations = _listData(result)
          .whereType<Map>()
          .map((item) => District.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> _load(Future<void> Function() operation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static void _requireSuccess(List<Map<String, dynamic>> results) {
    for (final result in results) {
      if (result['success'] != true) {
        throw Exception(result['error']?.toString() ?? 'Request failed');
      }
    }
  }

  static Map<String, dynamic> _mapData(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid object response from server');
  }

  static List<dynamic> _listData(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List) return data;
    throw Exception('Invalid list response from server');
  }
}

// ==================== MERCHANT PROVIDER ====================
class MerchantProvider extends ChangeNotifier {
  double _balance = 0;
  double _totalOwed = 0;
  List<MerchantPayment> _payments = [];
  bool _isLoading = false;
  String? _error;

  double get balance => _balance;
  double get totalOwed => _totalOwed;
  List<MerchantPayment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getMerchantBalance();
      final data = result['data'];

      if (result['success'] == true && data is Map) {
        _totalOwed = (data['totalOwed'] as num?)?.toDouble() ?? 0;
        _balance = (data['entitled'] as num?)?.toDouble() ?? 0;
      } else {
        _error = result['error']?.toString() ??
            'Invalid merchant balance data received from server.';
      }
    } catch (e) {
      _error = 'Failed to load merchant balance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getMerchantPayments();

      if (result['success'] == true && result['data'] is List) {
        _payments = (result['data'] as List)
            .map((item) => MerchantPayment.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      } else {
        _error = result['error']?.toString() ??
            'Invalid merchant payments data received from server.';
      }
    } catch (e) {
      _error = 'Failed to load merchant payments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
