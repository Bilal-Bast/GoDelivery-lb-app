import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/scanning/order_code_parser.dart';
import '../core/theme/app_tokens.dart';

enum ScanResultKind {
  valid,
  invalid,
  notFound,
  unauthorized,
  alreadySelected,
  notEligible,
  stale,
  error,
}

class OrderScanResult {
  final ScanResultKind kind;
  final String message;
  final String? orderId;
  final Object? data;

  const OrderScanResult({
    required this.kind,
    required this.message,
    this.orderId,
    this.data,
  });

  bool get isSuccess => kind == ScanResultKind.valid;
}

typedef OrderScanProcessor = Future<OrderScanResult> Function(String orderId);

Future<OrderScanResult?> showOrderScanner(
  BuildContext context, {
  required String title,
  required OrderScanProcessor process,
  bool closeAfterSuccess = false,
}) {
  return Navigator.of(context).push<OrderScanResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OrderScannerScreen(
        title: title,
        process: process,
        closeAfterSuccess: closeAfterSuccess,
      ),
    ),
  );
}

class OrderScannerScreen extends StatefulWidget {
  final String title;
  final OrderScanProcessor process;
  final bool closeAfterSuccess;
  final OrderCodeParser parser;

  const OrderScannerScreen({
    super.key,
    required this.title,
    required this.process,
    this.closeAfterSuccess = false,
    this.parser = const OrderCodeParser(),
  });

  @override
  State<OrderScannerScreen> createState() => _OrderScannerScreenState();
}

class _OrderScannerScreenState extends State<OrderScannerScreen> {
  final MobileScannerController _camera = MobileScannerController(
    formats: const [BarcodeFormat.code128, BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _manual = TextEditingController();
  final ScanGate _gate = ScanGate();
  OrderScanResult? _result;
  String? _cameraError;

  bool get _processing => _gate.state == ScanGateState.processing;

  @override
  void dispose() {
    _manual.dispose();
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetection(BarcodeCapture capture) async {
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value != null) await _accept(value);
  }

  Future<void> _accept(String rawValue) async {
    if (!_gate.tryLock()) return;
    setState(() => _result = null);
    final parsed = widget.parser.parse(rawValue);
    if (!parsed.isValid) {
      _finish(OrderScanResult(
        kind: ScanResultKind.invalid,
        message: parsed.message,
      ));
      return;
    }

    try {
      final result = await widget.process(parsed.orderId!);
      if (!mounted) return;
      if (result.isSuccess) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
      }
      _finish(result);
      if (result.isSuccess && widget.closeAfterSuccess && mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (error) {
      if (!mounted) return;
      _finish(OrderScanResult(
        kind: ScanResultKind.error,
        orderId: parsed.orderId,
        message: error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _finish(OrderScanResult result) {
    _gate.finish();
    if (mounted) setState(() => _result = result);
  }

  void _rearm() {
    _manual.clear();
    _gate.rearm();
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Close scanner',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle flashlight',
            onPressed: _camera.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: _camera.switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final preview = _ScannerPreview(
              camera: _camera,
              error: _cameraError,
              onDetect: _onDetection,
              onError: (message) => setState(() => _cameraError = message),
              onRetry: () {
                setState(() => _cameraError = null);
                _camera.start();
              },
            );
            final controls = _ScannerControls(
              manual: _manual,
              processing: _processing,
              result: _result,
              onSubmit: () => _accept(_manual.text),
              onRearm: _rearm,
              onDone: _result?.isSuccess == true
                  ? () => Navigator.of(context).pop(_result)
                  : () => Navigator.of(context).pop(),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.all(context.pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: preview),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(flex: 2, child: controls),
                          ],
                        )
                      : Column(
                          children: [
                            preview,
                            const SizedBox(height: AppSpacing.md),
                            controls,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScannerPreview extends StatelessWidget {
  final MobileScannerController camera;
  final String? error;
  final void Function(BarcodeCapture) onDetect;
  final ValueChanged<String> onError;
  final VoidCallback onRetry;

  const _ScannerPreview({
    required this.camera,
    required this.error,
    required this.onDetect,
    required this.onError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: error != null
            ? ColoredBox(
                color: Colors.black87,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_outlined,
                            color: Colors.white, size: 42),
                        const SizedBox(height: AppSpacing.sm),
                        Text(error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.tonalIcon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry camera'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: camera,
                    onDetect: onDetect,
                    errorBuilder: (context, scannerError) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onError(scannerError.errorCode ==
                                MobileScannerErrorCode.permissionDenied
                            ? 'Camera permission denied. Allow camera access or use manual entry.'
                            : 'Camera unavailable. Use manual entry or retry.');
                      });
                      return const ColoredBox(color: Colors.black87);
                    },
                  ),
                  Center(
                    child: Container(
                      width: 260,
                      height: 130,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      'Align the order barcode inside the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ScannerControls extends StatelessWidget {
  final TextEditingController manual;
  final bool processing;
  final OrderScanResult? result;
  final VoidCallback onSubmit;
  final VoidCallback onRearm;
  final VoidCallback onDone;

  const _ScannerControls({
    required this.manual,
    required this.processing,
    required this.result,
    required this.onSubmit,
    required this.onRearm,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = result?.isSuccess == true ? AppColors.teal : AppColors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              processing
                  ? 'Processing'
                  : result == null
                      ? 'Ready to scan'
                      : result!.message,
              key: const Key('scanner_status'),
              style: context.textStyles.titleMedium?.copyWith(
                color: result == null ? null : color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('scanner_manual_field'),
              controller: manual,
              enabled: !processing && result == null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                labelText: 'Manual order ID',
                hintText: 'Enter the ID printed below the barcode',
                prefixIcon: Icon(Icons.keyboard_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (processing)
              const LinearProgressIndicator()
            else if (result == null)
              FilledButton.icon(
                key: const Key('scanner_manual_submit'),
                onPressed: onSubmit,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Use order ID'),
              )
            else ...[
              FilledButton.icon(
                key: const Key('scanner_rearm_button'),
                onPressed: onRearm,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(result!.isSuccess ? 'Scan next' : 'Try again'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: onDone,
                child: Text(result!.isSuccess ? 'Use this order' : 'Done'),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Camera scanning may require HTTPS or localhost in a browser. Manual entry always remains available.',
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
