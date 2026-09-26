import 'order.dart';

class OrderLabelData {
  static const String barcodeSymbology = 'CODE128';

  final String orderId;
  final String location;
  final bool isExpress;

  const OrderLabelData({
    required this.orderId,
    required this.location,
    required this.isExpress,
  });

  String get barcodeValue => orderId;

  factory OrderLabelData.fromOrder(Order order) {
    final id = order.id;
    if (id.trim().isEmpty) {
      throw const FormatException('Order ID is required for a label.');
    }
    if (id != id.trim() ||
        id.length > 50 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(id)) {
      throw const FormatException('Order ID cannot be printed safely.');
    }
    final location = [order.city.trim(), order.district.trim()]
        .where((value) => value.isNotEmpty)
        .join(', ');
    return OrderLabelData(
      orderId: id,
      location: location,
      isExpress: order.isExpress,
    );
  }
}
