import 'dart:convert';

const legacyOrderImportHeaders = [
  'orderId',
  'merchant',
  'driver',
  'customerFirstName',
  'customerLastName',
  'customerPhone',
  'district',
  'city',
  'totalUSD',
  'deliveryChargeUSD',
  'isExpress',
  'expressNote',
];

const orderImportHeaders = [
  ...legacyOrderImportHeaders,
  'scheduledWindowStart',
  'scheduledWindowEnd',
];

class OrderCsvRow {
  final int rowNumber;
  final Map<String, String> values;
  final List<String> errors;

  const OrderCsvRow(this.rowNumber, this.values, this.errors);

  String get id => values['orderId'] ?? '';
  bool get valid => errors.isEmpty;

  Map<String, dynamic> toOrder({required bool merchant}) => {
        'id': id,
        if (!merchant) 'm': values['merchant'],
        if (!merchant && (values['driver'] ?? '').isNotEmpty)
          'driver': values['driver'],
        'c': {
          'f': values['customerFirstName'],
          'l': values['customerLastName'],
          'p': values['customerPhone'],
          'loc': {'d': values['district'], 'cty': values['city']},
        },
        'pr': {
          't': double.parse(values['totalUSD']!),
          'd': double.parse(values['deliveryChargeUSD']!),
        },
        's': 0,
        'e': (values['isExpress'] ?? '').toLowerCase() == 'true',
        'eN': values['expressNote'] ?? '',
        if ((values['scheduledWindowStart'] ?? '').isNotEmpty)
          'scheduledWindowStart': values['scheduledWindowStart'],
        if ((values['scheduledWindowEnd'] ?? '').isNotEmpty)
          'scheduledWindowEnd': values['scheduledWindowEnd'],
      };
}

class OrderCsvPreview {
  final List<OrderCsvRow> rows;
  const OrderCsvPreview(this.rows);
  int get validCount => rows.where((row) => row.valid).length;
  int get invalidCount => rows.length - validCount;
}

OrderCsvPreview parseOrderCsv(List<int> bytes, {required bool merchant}) {
  if (bytes.length > 1024 * 1024) {
    throw const FormatException('CSV exceeds 1 MB.');
  }
  var input = utf8.decode(bytes, allowMalformed: false);
  if (input.startsWith('\uFEFF')) input = input.substring(1);
  final records = <List<String>>[];
  final rowNumbers = <int>[];
  var cells = <String>[];
  var field = StringBuffer();
  var quoted = false;
  var line = 1;
  var rowStart = 1;
  for (var index = 0; index < input.length; index++) {
    final char = input[index];
    if (quoted) {
      if (char == '"') {
        if (index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
        if (char == '\n') line++;
      }
      continue;
    }
    if (char == '"' && field.isEmpty) {
      quoted = true;
    } else if (char == ',') {
      cells.add(field.toString().trim());
      field = StringBuffer();
    } else if (char == '\r' || char == '\n') {
      cells.add(field.toString().trim());
      if (cells.any((value) => value.isNotEmpty)) {
        records.add(cells);
        rowNumbers.add(rowStart);
      }
      cells = [];
      field = StringBuffer();
      if (char == '\r' &&
          index + 1 < input.length &&
          input[index + 1] == '\n') {
        index++;
      }
      line++;
      rowStart = line;
    } else {
      field.write(char);
    }
  }
  if (quoted) throw const FormatException('Unclosed quoted CSV field.');
  cells.add(field.toString().trim());
  if (cells.any((value) => value.isNotEmpty)) {
    records.add(cells);
    rowNumbers.add(rowStart);
  }
  if (records.isEmpty) throw const FormatException('CSV is empty.');
  final headers = records.first;
  if (headers.length != headers.toSet().length) {
    throw const FormatException('Duplicate CSV header.');
  }
  const allowedHeaders = {
    ...legacyOrderImportHeaders,
    'scheduledWindowStart',
    'scheduledWindowEnd'
  };
  if (!legacyOrderImportHeaders.every(headers.contains) ||
      headers.any((header) => !allowedHeaders.contains(header))) {
    throw const FormatException('CSV headers do not match the order template.');
  }
  if (records.length - 1 > 200) {
    throw const FormatException('CSV exceeds 200 orders.');
  }
  final rows = <OrderCsvRow>[];
  final seen = <String>{};
  for (var index = 1; index < records.length; index++) {
    final values = <String, String>{};
    final errors = <String>[];
    final record = records[index];
    if (record.length != headers.length) {
      errors.add('Expected ${headers.length} columns.');
    }
    for (var column = 0; column < headers.length; column++) {
      values[headers[column]] = column < record.length ? record[column] : '';
    }
    for (final key in [
      'orderId',
      'customerFirstName',
      'customerPhone',
      'district',
      'city',
      'totalUSD',
      'deliveryChargeUSD',
      if (!merchant) 'merchant'
    ]) {
      if ((values[key] ?? '').isEmpty) errors.add('$key is required.');
    }
    if ((values['orderId'] ?? '').length > 50) {
      errors.add('Order ID exceeds 50 characters.');
    }
    if (!seen.add(values['orderId'] ?? '')) {
      errors.add('Duplicate order ID in file.');
    }
    for (final key in ['totalUSD', 'deliveryChargeUSD']) {
      if ((values[key] ?? '').isNotEmpty &&
          double.tryParse(values[key]!) == null) {
        errors.add('$key must be numeric.');
      }
    }
    final express = (values['isExpress'] ?? '').toLowerCase();
    if (!['', 'true', 'false'].contains(express)) {
      errors.add('isExpress must be true or false.');
    }
    final scheduledStart = (values['scheduledWindowStart'] ?? '').trim();
    final scheduledEnd = (values['scheduledWindowEnd'] ?? '').trim();
    if (scheduledStart.isNotEmpty != scheduledEnd.isNotEmpty) {
      errors.add(
          'scheduledWindowStart and scheduledWindowEnd must both be provided.');
    } else if (scheduledStart.isNotEmpty) {
      final offsetTimestamp = RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,9})?)?(?:Z|[+-]\d{2}:\d{2})$');
      final start = offsetTimestamp.hasMatch(scheduledStart)
          ? DateTime.tryParse(scheduledStart)?.toUtc()
          : null;
      final end = offsetTimestamp.hasMatch(scheduledEnd)
          ? DateTime.tryParse(scheduledEnd)?.toUtc()
          : null;
      if (start == null) {
        errors.add(
            'scheduledWindowStart must be an ISO-8601 timestamp with a timezone offset.');
      }
      if (end == null) {
        errors.add(
            'scheduledWindowEnd must be an ISO-8601 timestamp with a timezone offset.');
      }
      if (start != null && end != null && !end.isAfter(start)) {
        errors.add('scheduledWindowEnd must be after scheduledWindowStart.');
      }
    }
    rows.add(OrderCsvRow(rowNumbers[index], values, errors));
  }
  return OrderCsvPreview(rows);
}

String orderCsvTemplate() =>
    '${orderImportHeaders.map(csvTextCell).join(',')}\r\n';

String csvTextCell(String value) {
  final safe = RegExp(r'^\s*[=+\-@]').hasMatch(value) ? "'$value" : value;
  return '"${safe.replaceAll('"', '""')}"';
}
