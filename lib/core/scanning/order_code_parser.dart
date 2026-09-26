enum OrderCodeError { empty, tooLong, malformed }

class OrderCodeParseResult {
  final String? orderId;
  final OrderCodeError? error;

  const OrderCodeParseResult._({this.orderId, this.error});

  const OrderCodeParseResult.valid(String orderId) : this._(orderId: orderId);

  const OrderCodeParseResult.invalid(OrderCodeError error)
      : this._(error: error);

  bool get isValid => orderId != null;

  String get message => switch (error) {
        OrderCodeError.empty => 'Enter or scan an order ID.',
        OrderCodeError.tooLong => 'Order IDs must be 50 characters or fewer.',
        OrderCodeError.malformed =>
          'This is not a supported GoDelivery order ID.',
        null => 'Valid order ID',
      };
}

class OrderCodeParser {
  const OrderCodeParser();

  /// Existing labels encode the authoritative `Order.id` as plain CODE128.
  /// The backend imposes no narrower character format, so this parser does not
  /// invent a prefix or transform values. It only applies the same 50-character
  /// boundary used by GET /api/orders/:id and rejects control or structured
  /// payloads that are not the plain value printed by current labels.
  OrderCodeParseResult parse(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return const OrderCodeParseResult.invalid(OrderCodeError.empty);
    }
    if (value.length > 50) {
      return const OrderCodeParseResult.invalid(OrderCodeError.tooLong);
    }
    if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
        value.contains('://') ||
        value.startsWith('{') ||
        value.startsWith('[')) {
      return const OrderCodeParseResult.invalid(OrderCodeError.malformed);
    }
    return OrderCodeParseResult.valid(value);
  }
}

enum ScanGateState { ready, processing, locked }

/// A camera-independent one-detection gate. A code can be accepted again only
/// after an explicit [rearm], preventing repeated frames from issuing requests.
class ScanGate {
  ScanGateState _state = ScanGateState.ready;

  ScanGateState get state => _state;
  bool get isReady => _state == ScanGateState.ready;

  bool tryLock() {
    if (!isReady) return false;
    _state = ScanGateState.processing;
    return true;
  }

  void finish() => _state = ScanGateState.locked;
  void rearm() => _state = ScanGateState.ready;
}
