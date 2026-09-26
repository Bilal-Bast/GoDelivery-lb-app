import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/order_label.dart';
import '../../services/order_label_pdf_service.dart';

class OrderLabelPreviewScreen extends StatefulWidget {
  final List<OrderLabelData> labels;
  final bool batch;

  const OrderLabelPreviewScreen({
    super.key,
    required this.labels,
    this.batch = false,
  });

  @override
  State<OrderLabelPreviewScreen> createState() =>
      _OrderLabelPreviewScreenState();
}

class _OrderLabelPreviewScreenState extends State<OrderLabelPreviewScreen> {
  final OrderLabelPdfService _service = OrderLabelPdfService();
  LabelPageMode _mode = LabelPageMode.thermal;
  late Future<OrderLabelPdfResult> _document;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    _document = widget.batch
        ? _service.buildBatch(widget.labels, mode: _mode)
        : _service.buildSingle(widget.labels.single, mode: _mode);
  }

  void _changeMode(LabelPageMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _generate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch
            ? 'Preview ${widget.labels.length} labels'
            : 'Preview label'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                AppSpacing.sm,
                context.pagePadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<LabelPageMode>(
                      segments: const [
                        ButtonSegment(
                          value: LabelPageMode.thermal,
                          icon: Icon(Icons.local_print_shop_outlined),
                          label: Text('35×15 mm thermal'),
                        ),
                        ButtonSegment(
                          value: LabelPageMode.a4Sheet,
                          icon: Icon(Icons.grid_view_outlined),
                          label: Text('A4 sheet'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) =>
                          _changeMode(selection.first),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
              child: Text(
                _mode == LabelPageMode.thermal
                    ? 'One exact 35×15 mm page per order. Select Actual size / 100% in the printer dialog.'
                    : 'Labels remain 35×15 mm on A4. Disable Fit to page or scaling.',
                style: context.textStyles.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<OrderLabelPdfResult>(
                future: _document,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Could not generate labels: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final result = snapshot.data!;
                  return PdfPreview(
                    key: ValueKey(_mode),
                    build: (_) async => result.bytes,
                    pdfFileName: result.filename,
                    initialPageFormat: result.pageFormat,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    allowPrinting: true,
                    allowSharing: true,
                    maxPageWidth: _mode == LabelPageMode.thermal ? 420 : 700,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
