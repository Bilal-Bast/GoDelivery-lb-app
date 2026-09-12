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
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.login(username: username, password: password);

    if (result['success']) {
      _currentUser = User.fromJson(result['user']);
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

  Future<void> logout() async {
    await ApiService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final userData = await ApiService.getUserData();
    if (userData != null) {
      _currentUser = User.fromJson(userData);
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

    final result = await ApiService.getOrders(status: status);

    if (result['success']) {
      final ordersList = (result['data'] as List)
          .map((o) => Order.fromJson(o))
          .toList();
      _orders = ordersList;
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.getOrder(orderId);

    if (result['success']) {
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

    if (result['success']) {
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

    if (result['success']) {
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

    final result = await ApiService.getDriverOrders(status: status);

    if (result['success']) {
      final ordersList = (result['data'] as List)
          .map((o) => Order.fromJson(o))
          .toList();
      _driverOrders = ordersList;
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCollections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.getDriverCollections();

    if (result['success']) {
      final collectionsList = (result['data'] as List)
          .map((c) => DriverCollection.fromJson(c))
          .toList();
      _collections = collectionsList;
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
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

    final result = await ApiService.getMerchantBalance();

    if (result['success']) {
      _totalOwed = (result['data']['totalOwed'] ?? 0).toDouble();
      _balance = (result['data']['entitled'] ?? 0).toDouble();
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.getMerchantPayments();

    if (result['success']) {
      final paymentsList = (result['data'] as List)
          .map((p) => MerchantPayment.fromJson(p))
          .toList();
      _payments = paymentsList;
    } else {
      _error = result['error'];
    }

    _isLoading = false;
    notifyListeners();
  }
}