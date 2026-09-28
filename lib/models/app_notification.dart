import 'user.dart';

const _orderTypes = {
  'ORDER_CREATED',
  'ORDER_ASSIGNED',
  'ORDER_PICKED_UP',
  'ORDER_DELIVERED',
  'ORDER_CANCELLED',
};

class AppNotification {
  final String id;
  final String type;
  final String entityType;
  final String entityId;
  final String title;
  final String body;
  final DateTime? createdAt;

  const AppNotification(
      {required this.id,
      required this.type,
      required this.entityType,
      required this.entityId,
      required this.title,
      required this.body,
      this.createdAt});

  static AppNotification? parse(Map<String, dynamic> data) {
    final type = data['type'];
    final entityType = data['entityType'];
    final entityId = data['entityId'];
    final id = data['id']?.toString() ?? '$type:$entityId';
    if (type is! String ||
        entityType is! String ||
        entityId is! String ||
        entityId.isEmpty ||
        entityId.length > 100 ||
        entityId.contains(RegExp(r'[\x00-\x1f]'))) {
      return null;
    }
    if (id.isEmpty || id.length > 200 || id.contains(RegExp(r'[\x00-\x1f]'))) {
      return null;
    }
    if (!_orderTypes.contains(type) &&
        !const {
          'ORDER_RETURNED',
          'DRIVER_COLLECTION_CREATED',
          'MERCHANT_PAYMENT_CREATED',
          'PREPAID_ADJUSTMENT_CREATED'
        }.contains(type)) {
      return null;
    }
    if (_orderTypes.contains(type) && entityType != 'order') {
      return null;
    }
    if (type == 'ORDER_RETURNED' && entityType != 'return') {
      return null;
    }
    if (type == 'DRIVER_COLLECTION_CREATED' && entityType != 'collection') {
      return null;
    }
    if (const {'MERCHANT_PAYMENT_CREATED', 'PREPAID_ADJUSTMENT_CREATED'}
            .contains(type) &&
        entityType != 'payment') {
      return null;
    }
    return AppNotification(
      id: id,
      type: type,
      entityType: entityType,
      entityId: entityId,
      title: 'GoDelivery update',
      body: _body(type),
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
    );
  }

  static String _body(String type) => switch (type) {
        'ORDER_CREATED' => 'A new order was created',
        'ORDER_ASSIGNED' => 'An order was assigned to you',
        'ORDER_PICKED_UP' => 'An order was picked up',
        'ORDER_DELIVERED' => 'An order was delivered',
        'ORDER_CANCELLED' => 'An order was cancelled',
        'ORDER_RETURNED' => 'A return was recorded',
        'DRIVER_COLLECTION_CREATED' => 'A driver collection was recorded',
        'MERCHANT_PAYMENT_CREATED' => 'A merchant payment was recorded',
        _ => 'A prepaid adjustment was recorded',
      };

  String? routeFor(User? user) {
    if (user == null) {
      return null;
    }
    if (user.isAdmin) {
      if (_orderTypes.contains(type)) {
        return '/home/orders/${Uri.encodeComponent(entityId)}';
      }
      return null;
    }
    if (user.isDriver) {
      if (const {'ORDER_ASSIGNED', 'ORDER_CANCELLED'}.contains(type)) {
        return '/home/driver-orders';
      }
      if (type == 'DRIVER_COLLECTION_CREATED') {
        return '/home/driver-collections';
      }
      return null;
    }
    if (user.isMerchant) {
      if (const {'ORDER_PICKED_UP', 'ORDER_DELIVERED', 'ORDER_CANCELLED'}
          .contains(type)) {
        return '/home/orders/${Uri.encodeComponent(entityId)}';
      }
      if (type == 'ORDER_RETURNED') {
        return '/home/merchant-balance';
      }
      if (const {'MERCHANT_PAYMENT_CREATED', 'PREPAID_ADJUSTMENT_CREATED'}
          .contains(type)) {
        return '/home/merchant-payments';
      }
    }
    return null;
  }
}
