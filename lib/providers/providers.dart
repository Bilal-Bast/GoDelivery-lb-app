import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/payment.dart';
import '../models/order.dart';
import '../models/collection.dart';
import '../models/district.dart';
import '../models/city.dart';
import '../models/admin_models.dart';
import '../models/driver_stats.dart';
import '../models/finance.dart';
import '../models/financial_operations.dart';
import '../models/public_tracking.dart';

import '../services/api_service.dart';

typedef StatusUpdateLoader = Future<Map<String, dynamic>> Function(
  String orderId,
  String status,
  String? note,
);
typedef OrderUpdateLoader = Future<Map<String, dynamic>> Function(
  String orderId,
  Map<String, dynamic> changes,
);
typedef OrderCancelLoader = Future<Map<String, dynamic>> Function(
  String orderId,
  String cancelledBy,
);

// ==================== AUTH PROVIDER ====================
enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class TrackingProvider extends ChangeNotifier {
  final Future<Map<String, dynamic>> Function(String) _loader;
  PublicTrackingOrder? order;
  bool isLoading = false;
  String? error;

  TrackingProvider({Future<Map<String, dynamic>> Function(String)? loader})
      : _loader = loader ?? ApiService.trackOrder;

  Future<bool> track(String id) async {
    if (isLoading) return false;
    isLoading = true;
    error = null;
    order = null;
    notifyListeners();
    try {
      final result = await _loader(id.trim());
      if (result['success'] != true || result['data'] is! Map) {
        error = result['error']?.toString() ?? 'Order not found';
        return false;
      }
      order = PublicTrackingOrder.fromJson(
        Map<String, dynamic>.from(result['data'] as Map),
      );
      return true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class PasswordFlowProvider extends ChangeNotifier {
  final Future<Map<String, dynamic>> Function(String) _forgot;
  final Future<Map<String, dynamic>> Function(String, String) _reset;
  bool isLoading = false;
  String? error;
  String? message;

  PasswordFlowProvider({
    Future<Map<String, dynamic>> Function(String)? forgot,
    Future<Map<String, dynamic>> Function(String, String)? reset,
  })  : _forgot = forgot ?? ApiService.forgotPassword,
        _reset = reset ??
            ((token, password) => ApiService.resetPassword(
                  token: token,
                  newPassword: password,
                ));

  Future<bool> requestReset(String email) => _run(() => _forgot(email.trim()));

  Future<bool> resetPassword(String token, String password) =>
      _run(() => _reset(token, password));

  Future<bool> _run(Future<Map<String, dynamic>> Function() action) async {
    if (isLoading) return false;
    isLoading = true;
    error = null;
    message = null;
    notifyListeners();
    try {
      final result = await action();
      if (result['success'] != true) {
        error = result['error']?.toString() ?? 'Request failed';
        return false;
      }
      message = result['message']?.toString() ?? 'Request completed';
      return true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class AuthProvider extends ChangeNotifier {
  final Future<bool> Function() _sessionExists;
  final Future<bool> Function() _sessionValidator;
  final Future<Map<String, dynamic>?> Function() _userLoader;
  final Future<void> Function() _clearSession;
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

  AuthProvider({
    Future<bool> Function()? sessionExists,
    Future<bool> Function()? sessionValidator,
    Future<Map<String, dynamic>?> Function()? userLoader,
    Future<void> Function()? clearSession,
  })  : _sessionExists = sessionExists ?? ApiService.isAuthenticated,
        _sessionValidator = sessionValidator ?? ApiService.validateSession,
        _userLoader = userLoader ?? ApiService.getUserData,
        _clearSession = clearSession ?? ApiService.logout;

  Future<void> restoreSession({bool refreshAccessToken = true}) async {
    _status = AuthStatus.initializing;
    _currentUser = null;
    _error = null;
    notifyListeners();

    try {
      final hasToken = await _sessionExists();
      final userData = await _userLoader();

      if (!hasToken || userData == null) {
        await _clearSession();
        _status = AuthStatus.unauthenticated;
        return;
      }

      if (refreshAccessToken && !await _sessionValidator()) {
        await _clearSession();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        return;
      }

      _currentUser = User.fromJson(
        await _userLoader() ?? userData,
      );
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _clearSession();
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
        if (!await _sessionValidator()) {
          await _clearSession();
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
          _error = 'Unable to verify the authenticated session';
          return false;
        }
        final profile = await _userLoader();
        if (profile != null) _currentUser = User.fromJson(profile);
        _status = AuthStatus.authenticated;
        return true;
      }

      await _clearSession();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _error = result['error']?.toString() ?? 'Login failed';
      return false;
    } catch (e) {
      await _clearSession();
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
      await _clearSession();
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (result['success'] == true) return true;
      _error = result['error']?.toString() ?? 'Password change failed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ==================== ORDER PROVIDER ====================
class OrderProvider extends ChangeNotifier {
  final Future<Map<String, dynamic>> Function(String orderId) _orderLoader;
  final StatusUpdateLoader _statusUpdater;
  final OrderUpdateLoader _orderUpdater;
  final OrderCancelLoader _orderCanceller;
  final Future<Map<String, dynamic>> Function(String) _historyLoader;
  final Future<Map<String, dynamic>> Function(String) _orderDeleter;
  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _orderPage = 1;
  int _orderPages = 1;
  String? _error;
  List<OrderHistoryEntry> _history = [];
  bool _isHistoryLoading = false;
  String? _historyError;
  final Set<String> _mutatingOrderIds = {};

  OrderProvider({
    Future<Map<String, dynamic>> Function(String orderId)? orderLoader,
    StatusUpdateLoader? statusUpdater,
    OrderUpdateLoader? orderUpdater,
    OrderCancelLoader? orderCanceller,
    Future<Map<String, dynamic>> Function(String)? historyLoader,
    Future<Map<String, dynamic>> Function(String)? orderDeleter,
  })  : _orderLoader = orderLoader ?? ApiService.getOrder,
        _statusUpdater = statusUpdater ??
            ((orderId, status, note) => ApiService.updateOrderStatus(
                  orderId: orderId,
                  status: status,
                  note: note,
                )),
        _orderUpdater = orderUpdater ??
            ((orderId, changes) => ApiService.updateOrder(
                  orderId: orderId,
                  changes: changes,
                )),
        _orderCanceller = orderCanceller ??
            ((orderId, cancelledBy) => ApiService.cancelOrder(
                  orderId: orderId,
                  cancelledBy: cancelledBy,
                )),
        _historyLoader = historyLoader ?? ApiService.getOrderHistory,
        _orderDeleter = orderDeleter ?? ApiService.deleteOrder;

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreOrders => _orderPage < _orderPages;
  String? get error => _error;
  List<OrderHistoryEntry> get history => _history;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;
  bool isUpdatingOrder(String orderId) => _mutatingOrderIds.contains(orderId);

  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await ApiService.getUserData();
      final result = await ApiService.getOrders(
        page: 1,
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
          _orderPage = 1;
          final pagination = result['pagination'];
          _orderPages = pagination is Map
              ? ((pagination['pages'] as num?)?.toInt() ?? 1)
              : 1;
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

  Future<void> fetchMoreOrders() async {
    if (_isLoadingMore || !hasMoreOrders) return;
    _isLoadingMore = true;
    _error = null;
    notifyListeners();
    try {
      final user = await ApiService.getUserData();
      final nextPage = _orderPage + 1;
      final result = await ApiService.getOrders(
        page: nextPage,
        currentMerchant: user?['role']?.toString().toLowerCase() == 'merchant',
      );
      if (result['success'] == true && result['data'] is List) {
        final incoming = (result['data'] as List)
            .whereType<Map>()
            .map((item) => Order.fromJson(Map<String, dynamic>.from(item)));
        final byId = {for (final order in _orders) order.id: order};
        for (final order in incoming) {
          byId[order.id] = order;
        }
        _orders = byId.values.toList();
        _orderPage = nextPage;
        final pagination = result['pagination'];
        if (pagination is Map) {
          _orderPages = (pagination['pages'] as num?)?.toInt() ?? _orderPages;
        }
      } else {
        _error = result['error']?.toString() ?? 'Failed to load more orders.';
      }
    } catch (error) {
      _error = 'Failed to load more orders: $error';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _orderLoader(orderId);
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

  Future<void> fetchHistory(String orderId) async {
    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      final result = await _historyLoader(orderId);
      if (result['success'] == true && result['data'] is List) {
        _history = (result['data'] as List)
            .whereType<Map>()
            .map((item) =>
                OrderHistoryEntry.fromJson(Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _historyError =
            result['error']?.toString() ?? 'Failed to load order history.';
      }
    } catch (error) {
      _historyError = 'Failed to load order history: $error';
    } finally {
      _isHistoryLoading = false;
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
    String? driverUsername,
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
        driverUsername: driverUsername,
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

  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    if (_mutatingOrderIds.contains(orderId)) return false;
    _mutatingOrderIds.add(orderId);
    _error = null;
    notifyListeners();

    try {
      final result = await _statusUpdater(orderId, status, note);
      final data = result['data'];
      if (result['success'] == true && data is Map) {
        final updatedOrder = Order.fromJson(Map<String, dynamic>.from(data));
        applyOrderUpdate(updatedOrder, notify: false);
        await _refreshOrderAfterSuccessfulMutation(orderId);
        await fetchHistory(orderId);
        return true;
      }
      _error = result['error']?.toString() ??
          'Invalid order data received from server.';
      await _refreshOrderAfterRejectedMutation(orderId);
      return false;
    } catch (error) {
      _error = 'Failed to update order: $error';
      await _refreshOrderAfterRejectedMutation(orderId);
      return false;
    } finally {
      _mutatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> updateOrder(
    String orderId,
    Map<String, dynamic> changes,
  ) async {
    return _mutateOrder(
      orderId,
      () => _orderUpdater(orderId, changes),
    );
  }

  Future<bool> cancelOrder(String orderId, String cancelledBy) async {
    return _mutateOrder(
      orderId,
      () => _orderCanceller(orderId, cancelledBy),
    );
  }

  Future<bool> deleteOrder(String orderId) async {
    if (_mutatingOrderIds.contains(orderId)) return false;
    _mutatingOrderIds.add(orderId);
    _error = null;
    notifyListeners();
    try {
      final result = await _orderDeleter(orderId);
      if (result['success'] == true) {
        _orders.removeWhere((order) => order.id == orderId);
        if (_selectedOrder?.id == orderId) _selectedOrder = null;
        _history = [];
        return true;
      }
      _error = result['error']?.toString() ?? 'Failed to delete order.';
      await _refreshOrderAfterRejectedMutation(orderId);
      return false;
    } catch (error) {
      _error = 'Failed to delete order: $error';
      await _refreshOrderAfterRejectedMutation(orderId);
      return false;
    } finally {
      _mutatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> _mutateOrder(
    String orderId,
    Future<Map<String, dynamic>> Function() operation,
  ) async {
    if (_mutatingOrderIds.contains(orderId)) return false;
    _mutatingOrderIds.add(orderId);
    _error = null;
    notifyListeners();
    try {
      final result = await operation();
      final data = result['data'];
      if (result['success'] == true && data is Map) {
        applyOrderUpdate(
          Order.fromJson(Map<String, dynamic>.from(data)),
          notify: false,
        );
        await _refreshOrderAfterSuccessfulMutation(orderId);
        await fetchHistory(orderId);
        return true;
      }
      _error = result['error']?.toString() ?? 'Failed to update order.';
      await _refreshOrderAfterRejectedMutation(orderId);
      return false;
    } catch (error) {
      _error = 'Failed to update order: $error';
      await _refreshOrderAfterRejectedMutation(orderId);
      return false;
    } finally {
      _mutatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  void applyOrderUpdate(Order order, {bool notify = true}) {
    final index = _orders.indexWhere((item) => item.id == order.id);
    if (index != -1) _orders[index] = order;
    if (_selectedOrder?.id == order.id) _selectedOrder = order;
    if (notify) notifyListeners();
  }

  Future<void> _refreshOrderAfterRejectedMutation(String orderId) async {
    final mutationError = _error;
    try {
      final result = await _orderLoader(orderId);
      final data = result['data'];
      if (result['success'] == true && data is Map) {
        applyOrderUpdate(
          Order.fromJson(Map<String, dynamic>.from(data)),
          notify: false,
        );
      }
    } catch (_) {
      // Keep the mutation error; the next manual refresh can retry the read.
    }
    _error = mutationError;
  }

  Future<void> _refreshOrderAfterSuccessfulMutation(String orderId) async {
    try {
      final result = await _orderLoader(orderId);
      final data = result['data'];
      if (result['success'] == true && data is Map) {
        applyOrderUpdate(
          Order.fromJson(Map<String, dynamic>.from(data)),
          notify: false,
        );
      }
    } catch (_) {
      // The mutation response remains usable; a manual refresh can retry.
    }
  }
}

// ==================== DRIVER PROVIDER ====================
class DriverProvider extends ChangeNotifier {
  final Future<Map<String, dynamic>> Function() _ordersLoader;
  final StatusUpdateLoader _statusUpdater;
  final Future<DriverStats> Function() _statsLoader;
  final Future<DriverCollectionPage> Function() _collectionsLoader;
  final Future<DriverBalance> Function() _balanceLoader;
  List<Order> _driverOrders = [];
  List<DriverCollection> _collections = [];
  DriverBalance? _balance;
  DriverStats? _stats;
  bool _isLoading = false;
  bool _isBalanceLoading = false;
  String? _error;
  String? _balanceError;
  final Set<String> _mutatingOrderIds = {};
  String? _driverStatusFilter;

  DriverProvider({
    Future<Map<String, dynamic>> Function()? ordersLoader,
    StatusUpdateLoader? statusUpdater,
    Future<DriverStats> Function()? statsLoader,
    Future<DriverCollectionPage> Function()? collectionsLoader,
    Future<DriverBalance> Function()? balanceLoader,
  })  : _ordersLoader = ordersLoader ?? ApiService.getDriverOrders,
        _statusUpdater = statusUpdater ??
            ((orderId, status, note) => ApiService.updateOrderStatus(
                  orderId: orderId,
                  status: status,
                  note: note,
                )),
        _statsLoader = statsLoader ?? ApiService.getDriverStats,
        _collectionsLoader =
            collectionsLoader ?? (() => ApiService.getDriverCollections()),
        _balanceLoader = balanceLoader ?? ApiService.getDriverBalance;

  List<Order> get driverOrders => _driverOrders;
  List<DriverCollection> get collections => _collections;
  DriverBalance? get balance => _balance;
  DriverStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isBalanceLoading => _isBalanceLoading;
  String? get error => _error;
  String? get balanceError => _balanceError;
  bool isUpdatingOrder(String orderId) => _mutatingOrderIds.contains(orderId);

  Future<void> fetchDriverOrders({String? status}) async {
    _driverStatusFilter = status;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _ordersLoader();

      if (result['success'] == true && result['data'] is List) {
        _applyDriverOrders(result['data'] as List, status);
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

  Future<void> fetchStats() async {
    try {
      _stats = await _statsLoader();
      notifyListeners();
    } catch (error) {
      _error = 'Failed to load driver statistics: $error';
      notifyListeners();
    }
  }

  Future<void> fetchCollections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _collectionsLoader();
      _collections = result.data;
    } catch (e) {
      _error = 'Failed to load collections: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBalance() async {
    _isBalanceLoading = true;
    _balanceError = null;
    notifyListeners();

    try {
      _balance = await _balanceLoader();
    } catch (e) {
      _balanceError = 'Failed to load outstanding balance: $e';
    } finally {
      _isBalanceLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    if (_mutatingOrderIds.contains(orderId)) return false;
    _mutatingOrderIds.add(orderId);
    _error = null;
    notifyListeners();

    try {
      final result = await _statusUpdater(orderId, status, note);
      if (result['success'] == true && result['data'] is Map) {
        applyOrderUpdate(
            Order.fromJson(
              Map<String, dynamic>.from(result['data'] as Map),
            ),
            notify: false);
        await fetchStats();
        return true;
      }
      _error = result['error']?.toString() ?? 'Failed to update order.';
      await _refreshOrdersAfterRejectedMutation();
      return false;
    } catch (error) {
      _error = 'Failed to update order: $error';
      await _refreshOrdersAfterRejectedMutation();
      return false;
    } finally {
      _mutatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  void applyOrderUpdate(Order order, {bool notify = true}) {
    final index = _driverOrders.indexWhere((item) => item.id == order.id);
    if (index != -1) _driverOrders[index] = order;
    if (notify) notifyListeners();
  }

  void _applyDriverOrders(List<dynamic> data, String? status) {
    final orders = data
        .whereType<Map>()
        .map((item) => Order.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    _driverOrders = status == null
        ? orders
        : orders
            .where(
                (order) => order.status.toUpperCase() == status.toUpperCase())
            .toList();
  }

  Future<void> _refreshOrdersAfterRejectedMutation() async {
    final mutationError = _error;
    try {
      final result = await _ordersLoader();
      if (result['success'] == true && result['data'] is List) {
        _applyDriverOrders(
          result['data'] as List,
          _driverStatusFilter,
        );
      }
    } catch (_) {
      // Preserve the backend mutation error for the user.
    }
    _error = mutationError;
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
  bool _mutationBusy = false;
  String? _mutationError;

  AnalyticsOverview? get analytics => _analytics;
  FinanceOverview? get finance => _finance;
  List<User> get users => _users;
  List<DriverSummary> get drivers => _drivers;
  List<DriverCollection> get collections => _collections;
  List<MerchantPayment> get payments => _payments;
  List<District> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get mutationBusy => _mutationBusy;
  String? get mutationError => _mutationError;

  Future<bool> createUser(String role, Map<String, dynamic> payload) =>
      _mutate(() => ApiService.createUser(role, payload), loadUsers);

  Future<bool> updateUserAccount(
    User user,
    Map<String, dynamic> commonChanges, {
    Map<String, dynamic>? roleChanges,
  }) =>
      _mutate(() async {
        final commonResult = commonChanges.isEmpty
            ? <String, dynamic>{'success': true}
            : await ApiService.updateUser(user.id, commonChanges);
        if (commonResult['success'] != true) return commonResult;
        if (roleChanges == null || roleChanges.isEmpty) return commonResult;
        return user.isDriver
            ? ApiService.updateDriver(user.id, roleChanges)
            : ApiService.updateMerchant(user.id, roleChanges);
      }, loadUsers);

  Future<Map<String, dynamic>> getDeletePreview(String id) =>
      ApiService.getUserDeletePreview(id);

  Future<bool> deleteUserAccount(String id) =>
      _mutate(() => ApiService.deleteUser(id), loadUsers);

  Future<bool> resetUserPassword(String id, String password) =>
      _mutate(() => ApiService.updateUserPassword(id, password), loadUsers);

  Future<bool> addLocation(String district, String cityEn, String cityAr) =>
      _mutate(
        () => ApiService.addLocation(
          district: district,
          cityEn: cityEn,
          cityAr: cityAr,
        ),
        loadLocations,
      );

  Future<bool> updateMerchantCharges(
    User merchant,
    Map<String, double> charges,
  ) =>
      _mutate(
        () => ApiService.updateMerchant(
          merchant.id,
          {'deliveryCharges': charges},
        ),
        loadUsers,
      );

  Future<bool> updateMerchantLegacyBalance(User merchant, double value) =>
      _mutate(
        () => ApiService.updateMerchantLegacyBalance(
          merchant.username,
          value,
        ),
        loadUsers,
      );

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

  Future<bool> _mutate(
    Future<Map<String, dynamic>> Function() operation,
    Future<void> Function() refresh,
  ) async {
    if (_mutationBusy) return false;
    _mutationBusy = true;
    _mutationError = null;
    notifyListeners();
    try {
      final result = await operation();
      if (result['success'] != true) {
        _mutationError = result['error']?.toString() ?? 'Request failed';
        try {
          await refresh();
        } catch (_) {
          // Preserve the mutation error; a manual refresh can retry the read.
        }
        return false;
      }
      await refresh();
      return true;
    } catch (error) {
      _mutationError = error.toString().replaceFirst('Exception: ', '');
      try {
        await refresh();
      } catch (_) {
        // Preserve the mutation error; a manual refresh can retry the read.
      }
      return false;
    } finally {
      _mutationBusy = false;
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

// ==================== ADMIN FINANCIAL OPERATIONS ====================
class FinancialOperationsProvider extends ChangeNotifier {
  final Future<Map<String, dynamic>> Function(String) _collectionEligibility;
  final Future<Map<String, dynamic>> Function(String, List<String>)
      _collectionPreview;
  final Future<Map<String, dynamic>> Function(String, List<String>, String)
      _collectionCreator;
  final Future<Map<String, dynamic>> Function(String) _paymentEligibility;
  final Future<Map<String, dynamic>> Function(String, List<String>)
      _paymentPreview;
  final Future<Map<String, dynamic>> Function(String, List<String>, String)
      _paymentCreator;
  final Future<Map<String, dynamic>> Function(String, double, String)
      _prepaidCreator;
  final Future<Map<String, dynamic>> Function(String) _returnEligibility;
  final Future<Map<String, dynamic>> Function(String, List<String>, String)
      _returnCreator;
  final Future<Map<String, dynamic>> Function() _collectionHistoryLoader;
  final Future<Map<String, dynamic>> Function() _paymentHistoryLoader;
  final Future<Map<String, dynamic>> Function() _returnHistoryLoader;

  List<SettlementSelectionOrder> collectionOrders = [];
  List<SettlementSelectionOrder> paymentOrders = [];
  List<ReturnableOrder> returnableOrders = [];
  List<DriverCollection> collectionHistory = [];
  List<MerchantPayment> paymentHistory = [];
  List<MerchantReturnRecord> returnHistory = [];
  final Set<String> selectedCollectionIds = {};
  final Set<String> selectedPaymentIds = {};
  final Set<String> selectedReturnIds = {};
  SettlementPreview? collectionPreview;
  SettlementPreview? paymentPreview;
  String? returnAccountType;
  final Set<String> _busy = {};
  final Map<String, String> _errors = {};

  FinancialOperationsProvider({
    Future<Map<String, dynamic>> Function(String)? collectionEligibility,
    Future<Map<String, dynamic>> Function(String, List<String>)?
        collectionPreviewLoader,
    Future<Map<String, dynamic>> Function(String, List<String>, String)?
        collectionCreator,
    Future<Map<String, dynamic>> Function(String)? paymentEligibility,
    Future<Map<String, dynamic>> Function(String, List<String>)?
        paymentPreviewLoader,
    Future<Map<String, dynamic>> Function(String, List<String>, String)?
        paymentCreator,
    Future<Map<String, dynamic>> Function(String, double, String)?
        prepaidCreator,
    Future<Map<String, dynamic>> Function(String)? returnEligibility,
    Future<Map<String, dynamic>> Function(String, List<String>, String)?
        returnCreator,
    Future<Map<String, dynamic>> Function()? collectionHistoryLoader,
    Future<Map<String, dynamic>> Function()? paymentHistoryLoader,
    Future<Map<String, dynamic>> Function()? returnHistoryLoader,
  })  : _collectionEligibility = collectionEligibility ??
            ((driver) => ApiService.getEligibleCollectionOrders(driver)),
        _collectionPreview = collectionPreviewLoader ??
            ((driver, ids) => ApiService.previewCollection(
                  driverUsername: driver,
                  orderIds: ids,
                )),
        _collectionCreator = collectionCreator ??
            ((driver, ids, notes) => ApiService.createCollection(
                  driverUsername: driver,
                  orderIds: ids,
                  notes: notes,
                )),
        _paymentEligibility = paymentEligibility ??
            ((merchant) => ApiService.getEligiblePaymentOrders(merchant)),
        _paymentPreview = paymentPreviewLoader ??
            ((merchant, ids) => ApiService.previewPayment(
                  merchantUsername: merchant,
                  orderIds: ids,
                )),
        _paymentCreator = paymentCreator ??
            ((merchant, ids, notes) => ApiService.createPayment(
                  merchantUsername: merchant,
                  orderIds: ids,
                  notes: notes,
                )),
        _prepaidCreator = prepaidCreator ??
            ((merchant, amount, notes) => ApiService.createPrepaidAdjustment(
                  merchantUsername: merchant,
                  amount: amount,
                  notes: notes,
                )),
        _returnEligibility =
            returnEligibility ?? ApiService.getReturnableOrders,
        _returnCreator = returnCreator ??
            ((merchant, ids, notes) => ApiService.createReturn(
                  merchantUsername: merchant,
                  orderIds: ids,
                  notes: notes,
                )),
        _collectionHistoryLoader =
            collectionHistoryLoader ?? (() => ApiService.getCollections()),
        _paymentHistoryLoader =
            paymentHistoryLoader ?? (() => ApiService.getPayments()),
        _returnHistoryLoader =
            returnHistoryLoader ?? (() => ApiService.getReturns());

  bool isBusy(String operation) => _busy.contains(operation);
  String? errorFor(String operation) => _errors[operation];

  Future<bool> loadCollectionEligibility(String driver) => _run(
        'collectionEligibility',
        () async {
          final result = await _collectionEligibility(driver);
          final data = _dataMap(result);
          collectionOrders = _maps(data['orders'])
              .map(SettlementSelectionOrder.collection)
              .toList();
          selectedCollectionIds.clear();
          collectionPreview = null;
        },
      );

  Future<bool> previewSelectedCollection(String driver) => _run(
        'collectionPreview',
        () async {
          final result =
              await _collectionPreview(driver, selectedCollectionIds.toList());
          collectionPreview = SettlementPreview.collection(_dataMap(result));
        },
      );

  Future<bool> createSelectedCollection(String driver, {String notes = ''}) =>
      _submitAndRefresh(
        'collectionCreate',
        () => _collectionCreator(driver, selectedCollectionIds.toList(), notes),
        () => loadCollectionEligibility(driver),
      );

  Future<bool> loadPaymentEligibility(String merchant) => _run(
        'paymentEligibility',
        () async {
          final result = await _paymentEligibility(merchant);
          final data = _dataMap(result);
          paymentOrders = _maps(data['orders'])
              .map(SettlementSelectionOrder.payment)
              .toList();
          selectedPaymentIds.clear();
          paymentPreview = null;
        },
      );

  Future<bool> previewSelectedPayment(String merchant) => _run(
        'paymentPreview',
        () async {
          final result =
              await _paymentPreview(merchant, selectedPaymentIds.toList());
          paymentPreview = SettlementPreview.payment(_dataMap(result));
        },
      );

  Future<bool> createSelectedPayment(String merchant, {String notes = ''}) =>
      _submitAndRefresh(
        'paymentCreate',
        () => _paymentCreator(merchant, selectedPaymentIds.toList(), notes),
        () => loadPaymentEligibility(merchant),
      );

  Future<bool> createPrepaidAdjustment(
    String merchant,
    double signedAmount, {
    String notes = '',
  }) =>
      _run(
        'prepaidCreate',
        () async {
          final result = await _prepaidCreator(merchant, signedAmount, notes);
          _requireSuccess([result]);
        },
      );

  Future<bool> loadReturnEligibility(String merchant) => _run(
        'returnEligibility',
        () async {
          final result = await _returnEligibility(merchant);
          _requireSuccess([result]);
          returnableOrders =
              _maps(result['data']).map(ReturnableOrder.fromJson).toList();
          final merchantData = result['merchant'];
          returnAccountType = merchantData is Map
              ? merchantData['accountType']?.toString()
              : null;
          selectedReturnIds.clear();
        },
      );

  Future<bool> createSelectedReturn(String merchant, {String notes = ''}) =>
      _submitAndRefresh(
        'returnCreate',
        () => _returnCreator(merchant, selectedReturnIds.toList(), notes),
        () => loadReturnEligibility(merchant),
      );

  Future<bool> loadHistories() => _run(
        'history',
        () async {
          final results = await Future.wait([
            _collectionHistoryLoader(),
            _paymentHistoryLoader(),
            _returnHistoryLoader(),
          ]);
          _requireSuccess(results);
          collectionHistory = _listData(results[0])
              .whereType<Map>()
              .map((item) =>
                  DriverCollection.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          paymentHistory = _listData(results[1])
              .whereType<Map>()
              .map((item) =>
                  MerchantPayment.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          returnHistory = _listData(results[2])
              .whereType<Map>()
              .map((item) => MerchantReturnRecord.fromJson(
                  Map<String, dynamic>.from(item)))
              .toList();
        },
      );

  void toggleCollection(String id) => _toggle(selectedCollectionIds, id,
      clearPreview: () => collectionPreview = null);
  void togglePayment(String id) => _toggle(selectedPaymentIds, id,
      clearPreview: () => paymentPreview = null);
  void toggleReturn(String id) => _toggle(selectedReturnIds, id);

  void _toggle(Set<String> target, String id, {VoidCallback? clearPreview}) {
    target.contains(id) ? target.remove(id) : target.add(id);
    clearPreview?.call();
    notifyListeners();
  }

  Future<bool> _submitAndRefresh(
    String operation,
    Future<Map<String, dynamic>> Function() submit,
    Future<bool> Function() refresh,
  ) async {
    if (_busy.contains(operation)) return false;
    final success = await _run(operation, () async {
      final result = await submit();
      _requireSuccess([result]);
    });
    if (success) {
      await refresh();
      await loadHistories();
    } else {
      await refresh();
    }
    return success;
  }

  Future<bool> _run(String operation, Future<void> Function() action) async {
    if (_busy.contains(operation)) return false;
    _busy.add(operation);
    _errors.remove(operation);
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _errors[operation] = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _busy.remove(operation);
      notifyListeners();
    }
  }

  static Map<String, dynamic> _dataMap(Map<String, dynamic> result) {
    _requireSuccess([result]);
    final data = result['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid financial operation response');
  }

  static List<dynamic> _listData(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List) return data;
    throw Exception('Invalid financial history response');
  }

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : const [];

  static void _requireSuccess(List<Map<String, dynamic>> results) {
    for (final result in results) {
      if (result['success'] != true) {
        throw Exception(result['error']?.toString() ?? 'Request failed');
      }
    }
  }
}

// ==================== MERCHANT PROVIDER ====================
class MerchantProvider extends ChangeNotifier {
  final Future<MerchantBalance> Function() _balanceLoader;
  final Future<MerchantPaymentPage> Function() _paymentsLoader;
  MerchantBalance? _balance;
  List<MerchantPayment> _payments = [];
  bool _isLoading = false;
  String? _error;

  MerchantProvider({
    Future<MerchantBalance> Function()? balanceLoader,
    Future<MerchantPaymentPage> Function()? paymentsLoader,
  })  : _balanceLoader = balanceLoader ?? ApiService.getMerchantBalance,
        _paymentsLoader =
            paymentsLoader ?? (() => ApiService.getMerchantPayments());

  MerchantBalance? get balance => _balance;
  List<MerchantPayment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _balance = await _balanceLoader();
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
      final result = await _paymentsLoader();
      _payments = result.data;
    } catch (e) {
      _error = 'Failed to load merchant payments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
