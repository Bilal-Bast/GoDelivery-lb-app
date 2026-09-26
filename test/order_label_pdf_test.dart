import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/models/order.dart';
import 'package:godelivery_lb_app/models/order_label.dart';
import 'package:godelivery_lb_app/screens/orders/orders_screens.dart';
import 'package:godelivery_lb_app/services/order_label_pdf_service.dart';
import 'package:pdf/pdf.dart';

Order _order({
  String id = 'ABC123',
  String city = 'Beirut',
  String district = 'Hamra',
  bool express = false,
}) =>
    Order(
      id: id,
      merchantId: 'merchant-one',
      customerFirstName: 'Maya',
      customerLastName: 'Haddad',
      customerPhone: '70123456',
      district: district,
      city: city,
      total: 100,
      deliveryCharge: 10,
      status: 'NEW',
      createdAt: DateTime.utc(2026, 9, 26),
      statusUpdatedAt: DateTime.utc(2026, 9, 26),
      isExpress: express,
    );

void main() {
  group('order label data', () {
    test('maps the authoritative Order.id directly to CODE128', () {
      final label = OrderLabelData.fromOrder(_order());
      expect(label.orderId, 'ABC123');
      expect(label.barcodeValue, 'ABC123');
      expect(OrderLabelData.barcodeSymbology, 'CODE128');
      expect(label.barcodeValue, isNot(startsWith('http')));
      expect(label.barcodeValue, isNot('ORDER-ABC123'));
      expect(label.barcodeValue, isNot(contains('{')));
    });

    test('preserves long valid IDs and maps express/location presentation', () {
      final id = List.filled(50, 'A').join();
      final label = OrderLabelData.fromOrder(
        _order(id: id, express: true),
      );
      expect(label.barcodeValue, id);
      expect(label.location, 'Beirut, Hamra');
      expect(label.isExpress, isTrue);
    });

    test('rejects missing and unsafe IDs but tolerates missing location', () {
      expect(
        () => OrderLabelData.fromOrder(_order(id: '')),
        throwsFormatException,
      );
      expect(
        () => OrderLabelData.fromOrder(_order(id: 'bad\nid')),
        throwsFormatException,
      );
      expect(
        () => OrderLabelData.fromOrder(_order(id: ' ABC123 ')),
        throwsFormatException,
      );
      expect(
        OrderLabelData.fromOrder(_order(city: '', district: '')).location,
        isEmpty,
      );
    });
  });

  group('physical PDF output', () {
    final service = OrderLabelPdfService();

    test('thermal page is exactly 35 by 15 millimetres', () async {
      final result = await service.buildSingle(
        OrderLabelData.fromOrder(_order()),
      );
      expect(result.pageCount, 1);
      expect(result.labelCount, 1);
      expect(
        result.pageFormat.width,
        closeTo(35 * PdfPageFormat.mm, 0.001),
      );
      expect(
        result.pageFormat.height,
        closeTo(15 * PdfPageFormat.mm, 0.001),
      );
      final mediaBoxes = OrderLabelPdfService.mediaBoxes(result.bytes);
      expect(mediaBoxes, hasLength(1));
      expect(mediaBoxes.single.width, closeTo(35 * PdfPageFormat.mm, 0.01));
      expect(mediaBoxes.single.height, closeTo(15 * PdfPageFormat.mm, 0.01));
      expect(result.bytes, isNotEmpty);
    });

    test('long valid IDs still generate a CODE128 PDF without substitution',
        () async {
      final id = List.filled(50, 'A').join();
      final result = await service.buildSingle(
        OrderLabelData.fromOrder(_order(id: id)),
      );
      expect(result.labels.single.barcodeValue, id);
      expect(result.pageCount, 1);
      expect(result.bytes, isNotEmpty);
    });

    test('batch de-duplicates, sorts deterministically and uses one page each',
        () async {
      final a = OrderLabelData.fromOrder(_order(id: 'A-1'));
      final b = OrderLabelData.fromOrder(_order(id: 'B-1'));
      final result = await service.buildBatch([b, a, b]);
      expect(result.labels.map((label) => label.orderId), ['A-1', 'B-1']);
      expect(result.labelCount, 2);
      expect(result.pageCount, 2);
      expect(OrderLabelPdfService.mediaBoxes(result.bytes), hasLength(2));
    });

    test('A4 sheet retains labels and paginates at the defined grid capacity',
        () async {
      final labels = List.generate(
        OrderLabelPdfService.a4LabelsPerPage + 1,
        (index) => OrderLabelData.fromOrder(
          _order(id: 'ORDER-${index.toString().padLeft(3, '0')}'),
        ),
      );
      final result = await service.buildBatch(
        labels,
        mode: LabelPageMode.a4Sheet,
      );
      expect(result.labelCount, labels.length);
      expect(result.pageCount, 2);
      expect(result.pageFormat, PdfPageFormat.a4);
      expect(OrderLabelPdfService.mediaBoxes(result.bytes), hasLength(2));
    });

    test('empty batches fail without producing a document', () async {
      expect(service.buildBatch(const []), throwsFormatException);
    });
  });

  test('filenames are deterministic and safe', () {
    expect(
      OrderLabelPdfService.singleFilename(r'ABC/12:*?'),
      'GoDelivery-Label-ABC_12_.pdf',
    );
    expect(
      OrderLabelPdfService.batchFilename(DateTime.utc(2026, 9, 26, 12, 3, 4)),
      'GoDelivery-Labels-20260926-120304Z.pdf',
    );
  });

  test('batch selection ignores stale IDs and duplicate loaded orders', () {
    final first = _order(id: 'A-1');
    final second = _order(id: 'B-1');
    final selected = selectedLabelOrders(
      [first, second, first],
      {'A-1', 'MISSING'},
    );
    expect(selected.map((order) => order.id), ['A-1']);
  });

  testWidgets('print label action appears only when the admin callback exists',
      (tester) async {
    Widget surface(VoidCallback? callback) => MaterialApp(
          home: Scaffold(
            body: AdminOrderControls(
              order: _order(),
              updating: false,
              onEdit: () {},
              onAssign: () {},
              onStatus: () {},
              onCancel: () {},
              onDelete: () {},
              onPrintLabel: callback,
            ),
          ),
        );

    await tester.pumpWidget(surface(() {}));
    expect(find.byKey(const Key('admin_print_label')), findsOneWidget);
    await tester.pumpWidget(surface(null));
    expect(find.byKey(const Key('admin_print_label')), findsNothing);
  });

  test('label generation is read-only and preserves order lifecycle state',
      () async {
    final order = _order();
    final before = order.toJson();
    await OrderLabelPdfService().buildSingle(OrderLabelData.fromOrder(order));
    expect(order.toJson(), before);
    expect(order.status, 'NEW');
  });
}
