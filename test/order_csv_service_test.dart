import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/services/order_csv_service.dart';

void main() {
  String csv(String row, {List<String> headers = legacyOrderImportHeaders}) =>
      '${headers.join(',')}\r\n$row\r\n';

  test('parses UTF-8, quoted comma, CRLF and optional blanks', () {
    final preview = parseOrderCsv(
        utf8.encode(
            csv('A1,shop,,"علي, Ahmad",,70123456,Beirut,Hamra,12.5,2,true,')),
        merchant: false);
    expect(preview.validCount, 1);
    expect(preview.rows.single.values['customerFirstName'], 'علي, Ahmad');
    expect(preview.rows.single.rowNumber, 2);
  });

  test('reports duplicates and invalid values with source rows', () {
    final preview = parseOrderCsv(
        utf8.encode(csv(
            'A1,shop,,Ali,,70123456,Beirut,Hamra,12,2,false,\nA1,shop,,Ali,,70123456,Beirut,Hamra,no,2,yes,')),
        merchant: false);
    expect(preview.validCount, 1);
    expect(preview.rows.last.rowNumber, 3);
    expect(preview.rows.last.errors.join(' '), contains('Duplicate order ID'));
    expect(preview.rows.last.errors.join(' '), contains('numeric'));
  });

  test('rejects duplicate or missing headers', () {
    expect(
        () =>
            parseOrderCsv(utf8.encode('orderId,orderId\nA,B'), merchant: false),
        throwsFormatException);
    expect(() => parseOrderCsv(utf8.encode('orderId\nA'), merchant: false),
        throwsFormatException);
  });

  test('template and export escaping are safe', () {
    expect(orderCsvTemplate(), contains('deliveryChargeUSD'));
    expect(csvTextCell('=SUM(1,1)'), '"\'=SUM(1,1)"');
    expect(csvTextCell('a,"b"'), '"a,""b"""');
  });

  test('keeps legacy CSV headers valid and validates optional schedule windows',
      () {
    final valid = parseOrderCsv(
      utf8.encode(
        csv(
          'A2,shop,,Ali,,70123456,Beirut,Hamra,12,2,false,,2026-10-30T11:00:00Z,2026-10-30T14:00:00Z',
          headers: orderImportHeaders,
        ),
      ),
      merchant: false,
    );
    expect(valid.validCount, 1);
    expect(valid.rows.single.toOrder(merchant: false)['scheduledWindowStart'],
        '2026-10-30T11:00:00Z');

    final partial = parseOrderCsv(
      utf8.encode(
        csv(
          'A3,shop,,Ali,,70123456,Beirut,Hamra,12,2,false,,2026-10-30T11:00:00Z,',
          headers: orderImportHeaders,
        ),
      ),
      merchant: false,
    );
    expect(partial.rows.single.errors.join(' '),
        contains('must both be provided'));

    final legacy = parseOrderCsv(
      utf8.encode(csv('A4,shop,,Ali,,70123456,Beirut,Hamra,12,2,false,')),
      merchant: false,
    );
    expect(legacy.validCount, 1);
  });
}
