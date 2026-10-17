import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/communication_contact_service.dart';

typedef WhatsAppPreviewLoader = Future<Map<String, dynamic>> Function(
  String orderId,
);

class CommunicationContactActions extends StatefulWidget {
  final Order order;
  final WhatsAppPreviewLoader loadPreview;
  final CommunicationContactService contactService;

  CommunicationContactActions({
    super.key,
    required this.order,
    WhatsAppPreviewLoader? loadPreview,
    CommunicationContactService? contactService,
  })  : loadPreview = loadPreview ?? ApiService.getWhatsAppPreview,
        contactService = contactService ?? CommunicationContactService();

  @override
  State<CommunicationContactActions> createState() =>
      _CommunicationContactActionsState();
}

class _CommunicationContactActionsState
    extends State<CommunicationContactActions> {
  bool _loading = false;

  Future<Map<String, dynamic>?> _preview() async {
    setState(() => _loading = true);
    try {
      final response = await widget.loadPreview(widget.order.id);
      if (response['success'] != true || response['available'] != true) {
        if (mounted) _showMessage('Customer phone is missing or invalid.');
        return null;
      }
      return response;
    } catch (_) {
      if (mounted) _showMessage('Could not load the customer contact preview.');
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _callCustomer() async {
    final preview = await _preview();
    if (preview == null || !mounted) return;
    final phone = preview['phone']?.toString() ?? '';
    final result = await widget.contactService.callCustomer(phone);
    if (mounted && result != ContactLaunchResult.launched) {
      _showMessage(result == ContactLaunchResult.invalidPhone
          ? 'The customer phone number is invalid.'
          : 'Calling is not available on this device.');
    }
  }

  Future<void> _whatsAppCustomer() async {
    final preview = await _preview();
    if (preview == null || !mounted) return;
    final phone = preview['phone']?.toString() ?? '';
    final text = preview['text']?.toString() ?? '';
    if (phone.isEmpty || text.isEmpty) {
      _showMessage('A WhatsApp preview is not available.');
      return;
    }
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: ${preview['maskedPhone'] ?? '***'}'),
            const SizedBox(height: AppSpacing.sm),
            const Text('Message preview'),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(text),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'WhatsApp opens with this message ready. You still need to press Send.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('whatsapp_preview_cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            key: const Key('whatsapp_preview_open'),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open WhatsApp'),
          ),
        ],
      ),
    );
    if (open != true || !mounted) return;
    final result = await widget.contactService.openWhatsApp(
      phone: phone,
      message: text,
    );
    if (!mounted) return;
    if (result == ContactLaunchResult.launched) {
      _showMessage(
          'WhatsApp opened. Press Send there to message the customer.');
    } else {
      _showMessage(result == ContactLaunchResult.invalidPhone
          ? 'The customer phone number is invalid.'
          : 'WhatsApp could not be opened on this device.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.order.customerPhone.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        const Text('Contact customer'),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              key: const Key('contact_customer_call'),
              onPressed: !available || _loading ? null : _callCustomer,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call'),
            ),
            FilledButton.tonalIcon(
              key: const Key('contact_customer_whatsapp'),
              onPressed: !available || _loading ? null : _whatsAppCustomer,
              icon: const Icon(Icons.chat_outlined),
              label: Text(_loading ? 'Loading…' : 'WhatsApp'),
            ),
          ],
        ),
        if (!available)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Customer phone is not available.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
