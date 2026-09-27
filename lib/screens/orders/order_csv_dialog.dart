import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/api_service.dart';
import '../../services/order_csv_service.dart';

Future<void> saveOrderCsv(String fileName, List<int> bytes) async {
  final data = Uint8List.fromList(bytes);
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    await FilePicker.saveFile(
        fileName: fileName, bytes: data, mimeType: 'text/csv');
  } else {
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(data, mimeType: 'text/csv', name: fileName)],
      fileNameOverrides: [fileName],
    ));
  }
}

class OrderCsvImportDialog extends StatefulWidget {
  final bool merchant;
  final VoidCallback onImported;

  const OrderCsvImportDialog(
      {super.key, required this.merchant, required this.onImported});

  @override
  State<OrderCsvImportDialog> createState() => _OrderCsvImportDialogState();
}

class _OrderCsvImportDialogState extends State<OrderCsvImportDialog> {
  OrderCsvPreview? _preview;
  Map<int, List<String>> _serverErrors = {};
  String? _error;
  bool _busy = false;
  bool _serverValidated = false;
  bool _imported = false;
  final List<String> _created = [];
  final Map<int, String> _failures = {};

  Future<void> _choose() async {
    if (_busy) return;
    try {
      final files = await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: ['csv']);
      if (files.isEmpty) return;
      final file = files.first;
      if ((file.lengthSync() ?? await file.length() ?? 0) > 1024 * 1024) {
        throw const FormatException('CSV exceeds 1 MB.');
      }
      final preview =
          parseOrderCsv(await file.readAsBytes(), merchant: widget.merchant);
      setState(() {
        _preview = preview;
        _serverErrors = {};
        _error = null;
        _imported = false;
        _serverValidated = false;
      });
      final valid = preview.rows.where((row) => row.valid).toList();
      if (valid.isEmpty) return;
      setState(() => _busy = true);
      final result = await ApiService.previewOrderImport([
        for (final row in valid)
          {
            'rowNumber': row.rowNumber,
            'order': row.toOrder(merchant: widget.merchant)
          }
      ]);
      if (result['success'] != true) {
        throw ApiException(result['error']?.toString() ?? 'Preview failed');
      }
      final data = result['data'] is Map ? result['data'] as Map : result;
      final errors = <int, List<String>>{};
      for (final item in (data['rows'] as List? ?? const [])) {
        if (item is Map && item['errors'] is List) {
          final rowErrors = (item['errors'] as List)
              .map((error) => error.toString())
              .toList();
          if (rowErrors.isNotEmpty) {
            errors[(item['rowNumber'] as num).toInt()] = rowErrors;
          }
        }
      }
      if (mounted) {
        setState(() {
          _serverErrors = errors;
          _serverValidated = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy || !_serverValidated || _preview == null) return;
    final rows = _preview!.rows
        .where((row) => row.valid && !_serverErrors.containsKey(row.rowNumber))
        .toList();
    if (rows.isEmpty) return;
    setState(() {
      _busy = true;
      _created.clear();
      _failures.clear();
    });
    for (final row in rows) {
      try {
        final result = await ApiService.createOrderPayload(
            row.toOrder(merchant: widget.merchant));
        if (result['success'] == true) {
          _created.add(row.id);
        } else {
          _failures[row.rowNumber] =
              result['error']?.toString() ?? 'Creation failed';
        }
      } catch (error) {
        _failures[row.rowNumber] = error.toString();
      }
      if (!mounted) return;
      setState(() {});
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _imported = true;
    });
    if (_created.isNotEmpty) widget.onImported();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final valid = preview?.rows
            .where(
                (row) => row.valid && !_serverErrors.containsKey(row.rowNumber))
            .length ??
        0;
    return AlertDialog(
      title: const Text('Import orders from CSV'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Required: orderId, customerFirstName, customerPhone, district, city, totalUSD, deliveryChargeUSD. Admin also requires merchant. Optional: driver, customerLastName, isExpress, expressNote. USD values are plain numbers.'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => saveOrderCsv(
                      'GoDelivery-Order-Import-Template.csv',
                      utf8.encode(orderCsvTemplate())),
                  icon: const Icon(Icons.download),
                  label: const Text('Download template'),
                ),
                OutlinedButton.icon(
                    onPressed: _busy ? null : _choose,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose CSV')),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                if (preview != null) ...[
                  const SizedBox(height: 12),
                  Text(
                      '${preview.rows.length} rows • $valid ready • ${preview.rows.length - valid} invalid'),
                  const Text(
                      'Validated rows are created one at a time. A later failure does not undo earlier orders.'),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: preview.rows.length,
                      itemBuilder: (context, index) {
                        final row = preview.rows[index];
                        final errors = [
                          ...row.errors,
                          ...?_serverErrors[row.rowNumber]
                        ];
                        return ListTile(
                          dense: true,
                          title: Text(
                              'Row ${row.rowNumber}: ${row.id} • ${row.values['merchant']} • ${row.values['district']}/${row.values['city']} • USD ${row.values['totalUSD']} • Express ${row.values['isExpress']}'),
                          subtitle: errors.isEmpty
                              ? const Text('Ready')
                              : Text(errors.join(' ')),
                          leading: Icon(errors.isEmpty
                              ? Icons.check_circle_outline
                              : Icons.error_outline),
                        );
                      },
                    ),
                  ),
                ],
                if (_imported) ...[
                  Text(
                      'Created ${_created.length}; rejected ${_failures.length}.'),
                  if (_created.isNotEmpty)
                    Text('Created IDs: ${_created.join(', ')}'),
                  for (final failure in _failures.entries)
                    Text('Row ${failure.key}: ${failure.value}'),
                ],
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Close')),
        FilledButton(
            onPressed: _busy || !_serverValidated || valid == 0 || _imported
                ? null
                : _import,
            child: const Text('Confirm import')),
      ],
    );
  }
}
