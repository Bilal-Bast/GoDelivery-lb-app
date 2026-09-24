import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../models/order_status.dart';

class OrderActionButtons extends StatelessWidget {
  final String role;
  final OrderStatusValue status;
  final bool updating;
  final String keyPrefix;
  final ValueChanged<OrderMutationAction> onAction;

  const OrderActionButtons({
    super.key,
    required this.role,
    required this.status,
    required this.updating,
    required this.keyPrefix,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = availableOrderActions(role: role, status: status);
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        for (final action in actions) _button(context, action),
      ],
    );
  }

  Widget _button(BuildContext context, OrderMutationAction action) {
    final label = switch (action) {
      OrderMutationAction.pickUp => 'Pick Up',
      OrderMutationAction.deliver =>
        role.toLowerCase() == 'admin' ? 'Mark as delivered' : 'Delivered',
      OrderMutationAction.cancel => 'Cancelled',
    };
    final icon = updating
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(switch (action) {
            OrderMutationAction.pickUp => Icons.local_shipping_outlined,
            OrderMutationAction.deliver => Icons.check_circle_outline_rounded,
            OrderMutationAction.cancel => Icons.cancel_outlined,
          });
    final key = Key('${keyPrefix}_${action.name}');
    if (action == OrderMutationAction.cancel) {
      return OutlinedButton.icon(
        key: key,
        onPressed: updating ? null : () => onAction(action),
        icon: icon,
        label: Text(label),
      );
    }
    return FilledButton.icon(
      key: key,
      onPressed: updating ? null : () => onAction(action),
      icon: icon,
      label: Text(label),
    );
  }
}

class OrderActionConfirmation {
  final String? note;

  const OrderActionConfirmation({this.note});
}

class OrderActionConfirmationDialog extends StatefulWidget {
  final OrderMutationAction action;

  const OrderActionConfirmationDialog({
    super.key,
    required this.action,
  });

  @override
  State<OrderActionConfirmationDialog> createState() =>
      _OrderActionConfirmationDialogState();
}

class _OrderActionConfirmationDialogState
    extends State<OrderActionConfirmationDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cancelling = widget.action == OrderMutationAction.cancel;
    return AlertDialog(
      icon: Icon(
        cancelling ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
        color: cancelling ? AppColors.red : AppColors.teal,
      ),
      title: Text(cancelling ? 'Mark as cancelled?' : 'Mark as delivered?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cancelling
              ? 'Confirm that this delivery was cancelled. This status is visible to operations.'
              : 'Confirm that the order reached the customer.'),
          if (cancelling) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('driver_cancellation_note'),
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Operational note (optional)',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Go back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            OrderActionConfirmation(
              note: cancelling ? _noteController.text.trim() : null,
            ),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
