import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/user.dart';
import '../models/payment.dart';
import '../models/order.dart';
import '../models/collection.dart';
import '../models/district.dart';
import '../models/city.dart';

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

      if (refreshAccessToken && !await ApiService.refreshToken()) {
        _status = AuthStatus.unauthenticated;
        return;
      }

      _currentUser = User.fromJson(userData);
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
      final result = await ApiService.getOrders(status: status);

      if (result['success'] == true) {
        final data = result['data'];

        if (data is List) {
          _orders = data
              .map((o) => Order.fromJson(o as Map<String, dynamic>))
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

    final result = await ApiService.getOrder(orderId);

    if (result['success'] == true) {
      _selectedOrder = Order.fromJson(result['data']);
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createOrder({
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

    final result = await ApiService.createOrder(
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

    if (result['success'] == true) {
      final newOrder = Order.fromJson(result['data']);
      _orders.insert(0, newOrder);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.updateOrderStatus(
      orderId: orderId,
      status: status,
    );

    if (result['success'] == true) {
      final updatedOrder = Order.fromJson(result['data']);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      _isLoading = false;
      notifyListeners();
      return false;
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
      final result = await ApiService.getDriverOrders(status: status);

      if (result['success'] == true && result['data'] is List) {
        _driverOrders = (result['data'] as List)
            .map((item) => Order.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
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
