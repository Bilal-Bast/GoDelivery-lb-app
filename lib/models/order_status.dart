enum OrderStatusValue {
  unknown(-1, 'UNKNOWN', 'Unknown'),
  warehouse(0, 'WAREHOUSE', 'Warehouse'),
  newOrder(1, 'NEW', 'New'),
  pickedUp(2, 'PICKED_UP', 'Picked up'),
  delivered(3, 'DELIVERED', 'Delivered'),
  cancelled(4, 'CANCELLED', 'Cancelled'),
  paid(5, 'PAID', 'Paid'),
  collected(6, 'COLLECTED', 'Collected');

  final int number;
  final String code;
  final String label;

  const OrderStatusValue(this.number, this.code, this.label);

  static OrderStatusValue fromBackend(dynamic value) {
    if (value is num) return fromNumber(value.toInt());
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return warehouse;
    final numeric = int.tryParse(raw);
    if (numeric != null) return fromNumber(numeric);
    final normalized = raw.toUpperCase().replaceAll(' ', '_');
    return switch (normalized) {
      'NEW' => newOrder,
      'PICKED_UP' || 'PICKEDUP' => pickedUp,
      'DELIVERED' => delivered,
      'CANCELLED' || 'CANCELED' => cancelled,
      'PAID' => paid,
      'COLLECTED' => collected,
      'WAREHOUSE' => warehouse,
      _ => unknown,
    };
  }

  static OrderStatusValue fromNumber(int value) {
    return values.where((status) => status.number == value).firstOrNull ??
        unknown;
  }

  bool get isPending => this == warehouse || this == newOrder;
  bool get isTerminal => const {
        delivered,
        cancelled,
        collected,
        paid,
      }.contains(this);
}

enum OrderMutationAction { pickUp, deliver, cancel }

const adminOperationalStatuses = [
  OrderStatusValue.warehouse,
  OrderStatusValue.newOrder,
  OrderStatusValue.pickedUp,
  OrderStatusValue.delivered,
  OrderStatusValue.cancelled,
];

List<OrderMutationAction> availableOrderActions({
  required String role,
  required OrderStatusValue status,
}) {
  switch (role.trim().toLowerCase()) {
    case 'driver':
      return switch (status) {
        OrderStatusValue.warehouse || OrderStatusValue.newOrder => const [
            OrderMutationAction.pickUp
          ],
        OrderStatusValue.pickedUp => const [
            OrderMutationAction.deliver,
            OrderMutationAction.cancel,
          ],
        _ => const [],
      };
    case 'admin':
      return const [];
    default:
      return const [];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
