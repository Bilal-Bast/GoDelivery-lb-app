import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/order_label.dart';

enum LabelPageMode { thermal, a4Sheet }

class OrderLabelPdfResult {
  final Uint8List bytes;
  final String filename;
  final LabelPageMode mode;
  final int labelCount;
  final int pageCount;
  final PdfPageFormat pageFormat;
  final List<OrderLabelData> labels;

  const OrderLabelPdfResult({
    required this.bytes,
    required this.filename,
    required this.mode,
    required this.labelCount,
    required this.pageCount,
    required this.pageFormat,
    required this.labels,
  });
}

class OrderLabelPdfService {
  static const double labelWidthMm = 35;
  static const double labelHeightMm = 15;
  static const int a4Columns = 5;
  static const int a4Rows = 18;
  static const int a4LabelsPerPage = a4Columns * a4Rows;

  static const PdfPageFormat thermalPageFormat = PdfPageFormat(
    labelWidthMm * PdfPageFormat.mm,
    labelHeightMm * PdfPageFormat.mm,
    marginAll: 0,
  );

  static String safeFilenamePart(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.isEmpty ? 'Order' : sanitized;
  }

  static String singleFilename(String orderId) =>
      'GoDelivery-Label-${safeFilenamePart(orderId)}.pdf';

  static String batchFilename(DateTime timestamp) {
    final utc = timestamp.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'GoDelivery-Labels-${utc.year}${two(utc.month)}${two(utc.day)}-'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z.pdf';
  }

  Future<OrderLabelPdfResult> buildSingle(
    OrderLabelData label, {
    LabelPageMode mode = LabelPageMode.thermal,
  }) =>
      buildBatch(
        [label],
        mode: mode,
        filename: singleFilename(label.orderId),
      );

  Future<OrderLabelPdfResult> buildBatch(
    Iterable<OrderLabelData> source, {
    LabelPageMode mode = LabelPageMode.thermal,
    String? filename,
    DateTime? timestamp,
  }) async {
    final byId = <String, OrderLabelData>{};
    for (final label in source) {
      if (label.orderId.trim().isEmpty) continue;
      byId[label.orderId] = label;
    }
    final labels = byId.values.toList()
      ..sort((a, b) => a.orderId.compareTo(b.orderId));
    if (labels.isEmpty) {
      throw const FormatException('Select at least one order to print.');
    }

    final document = pw.Document(
      title: labels.length == 1
          ? 'GoDelivery Label ${labels.single.orderId}'
          : 'GoDelivery Labels',
      author: 'GoDelivery',
      creator: 'GoDelivery Flutter',
    );
    final pageCount = mode == LabelPageMode.thermal
        ? _addThermalPages(document, labels)
        : _addA4Pages(document, labels);
    final bytes = await document.save();
    return OrderLabelPdfResult(
      bytes: bytes,
      filename: filename ?? batchFilename(timestamp ?? DateTime.now()),
      mode: mode,
      labelCount: labels.length,
      pageCount: pageCount,
      pageFormat:
          mode == LabelPageMode.thermal ? thermalPageFormat : PdfPageFormat.a4,
      labels: List.unmodifiable(labels),
    );
  }

  int _addThermalPages(pw.Document document, List<OrderLabelData> labels) {
    for (final label in labels) {
      document.addPage(
        pw.Page(
          pageFormat: thermalPageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => _label(label),
        ),
      );
    }
    return labels.length;
  }

  int _addA4Pages(pw.Document document, List<OrderLabelData> labels) {
    final chunks = <List<OrderLabelData>>[];
    for (var start = 0; start < labels.length; start += a4LabelsPerPage) {
      chunks.add(labels.sublist(
        start,
        (start + a4LabelsPerPage).clamp(0, labels.length),
      ));
    }
    for (final chunk in chunks) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var row = 0; row < a4Rows; row++)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (var column = 0; column < a4Columns; column++)
                      if (row * a4Columns + column < chunk.length)
                        _label(chunk[row * a4Columns + column], border: true)
                      else
                        pw.SizedBox(
                          width: labelWidthMm * PdfPageFormat.mm,
                          height: labelHeightMm * PdfPageFormat.mm,
                        ),
                  ],
                ),
            ],
          ),
        ),
      );
    }
    return chunks.length;
  }

  pw.Widget _label(OrderLabelData label, {bool border = false}) {
    return pw.Container(
      width: labelWidthMm * PdfPageFormat.mm,
      height: labelHeightMm * PdfPageFormat.mm,
      decoration:
          border ? pw.BoxDecoration(border: pw.Border.all(width: 0.25)) : null,
      padding: const pw.EdgeInsets.fromLTRB(
        // Keep white space around the bars inside the physical label.
        3 * PdfPageFormat.mm,
        0.7 * PdfPageFormat.mm,
        3 * PdfPageFormat.mm,
        0.5 * PdfPageFormat.mm,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: label.barcodeValue,
              drawText: false,
              color: PdfColors.black,
              backgroundColor: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 0.35 * PdfPageFormat.mm),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  label.orderId,
                  maxLines: 1,
                  style: const pw.TextStyle(
                    fontSize: 5.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (label.location.isNotEmpty) ...[
                pw.SizedBox(width: 0.7 * PdfPageFormat.mm),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    label.location,
                    maxLines: 1,
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 3.8),
                  ),
                ),
              ],
              if (label.isExpress) ...[
                pw.SizedBox(width: 0.7 * PdfPageFormat.mm),
                pw.Container(
                  color: PdfColors.black,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 0.7 * PdfPageFormat.mm,
                    vertical: 0.2 * PdfPageFormat.mm,
                  ),
                  child: pw.Text(
                    'EXP',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 3.8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static List<PdfPageFormat> mediaBoxes(Uint8List bytes) {
    final source = latin1.decode(bytes, allowInvalid: true);
    final matches = RegExp(
      r'/MediaBox\s*\[\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)\s*\]',
    ).allMatches(source);
    return matches
        .map((match) => PdfPageFormat(
              double.parse(match.group(1)!),
              double.parse(match.group(2)!),
            ))
        .toList();
  }
}
