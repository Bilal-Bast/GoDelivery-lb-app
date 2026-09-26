import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/admin_models.dart';
import '../../models/financial_operations.dart';
import '../../models/user.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';
import '../../widgets/order_scanner.dart';

class AdminFinancialOperations extends StatefulWidget {
  final AdminProvider admin;
  final bool isAdmin;
  final Future<void> Function() onRefresh;

  const AdminFinancialOperations({
    super.key,
    required this.admin,
    required this.isAdmin,
    required this.onRefresh,
  });

  @override
  State<AdminFinancialOperations> createState() =>
      _AdminFinancialOperationsState();
}

class _AdminFinancialOperationsState extends State<AdminFinancialOperations> {
  String? _driver;
  String? _postpaidMerchant;
  String? _prepaidMerchant;
  String? _returnMerchant;

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (widget.admin.users.isEmpty) await widget.admin.loadUsers();
        if (!mounted) return;
        await context.read<FinancialOperationsProvider>().loadHistories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) return const SizedBox.shrink();
    final operations = context.watch<FinancialOperationsProvider>();
    final drivers = widget.admin.users.where((user) => user.isDriver).toList();
    final merchants =
        widget.admin.users.where((user) => user.isMerchant).toList();
    final postpaid = merchants
        .where((user) => user.accountType?.toUpperCase() != 'PREPAID')
        .toList();
    final prepaid = merchants
        .where((user) => user.accountType?.toUpperCase() == 'PREPAID')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Financial operations',
          subtitle: 'Backend-validated collections, payments and returns',
        ),
        const SizedBox(height: AppSpacing.md),
        _CollectionPanel(
          drivers: drivers,
          selected: _driver,
          operations: operations,
          onChanged: (value) {
            setState(() => _driver = value);
            if (value != null) operations.loadCollectionEligibility(value);
          },
          afterMutation: _refreshAuthoritativeState,
        ),
        const SizedBox(height: AppSpacing.md),
        _PaymentPanel(
          merchants: postpaid,
          selected: _postpaidMerchant,
          operations: operations,
          onChanged: (value) {
            setState(() => _postpaidMerchant = value);
            if (value != null) operations.loadPaymentEligibility(value);
          },
          afterMutation: _refreshAuthoritativeState,
        ),
        const SizedBox(height: AppSpacing.md),
        _PrepaidPanel(
          merchants: prepaid,
          balances: widget.admin.finance?.merchants ?? const [],
          selected: _prepaidMerchant,
          operations: operations,
          onChanged: (value) => setState(() => _prepaidMerchant = value),
          afterMutation: _refreshAuthoritativeState,
        ),
        const SizedBox(height: AppSpacing.md),
        _ReturnPanel(
          merchants: merchants,
          selected: _returnMerchant,
          operations: operations,
          onChanged: (value) {
            setState(() => _returnMerchant = value);
            if (value != null) operations.loadReturnEligibility(value);
          },
          afterMutation: _refreshAuthoritativeState,
        ),
        const SizedBox(height: AppSpacing.md),
        _HistoryPanel(operations: operations),
      ],
    );
  }

  Future<void> _refreshAuthoritativeState() async {
    await widget.onRefresh();
    if (!mounted) return;
    await context.read<OrderProvider>().fetchOrders();
  }
}

class _CollectionPanel extends StatelessWidget {
  final List<User> drivers;
  final String? selected;
  final FinancialOperationsProvider operations;
  final ValueChanged<String?> onChanged;
  final Future<void> Function() afterMutation;

  const _CollectionPanel({
    required this.drivers,
    required this.selected,
    required this.operations,
    required this.onChanged,
    required this.afterMutation,
  });

  @override
  Widget build(BuildContext context) => _OperationCard(
        title: 'Driver collection',
        subtitle:
            'Collect delivered/cancelled cash through one atomic settlement',
        children: [
          _UserPicker(
            label: 'Driver',
            users: drivers,
            value: selected,
            onChanged: onChanged,
          ),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('collection_scan_button'),
                onPressed: operations.isBusy('collectionEligibility')
                    ? null
                    : () => _scanCollection(context),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan orders'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SelectionList(
              loading: operations.isBusy('collectionEligibility'),
              error: operations.errorFor('collectionEligibility'),
              emptyText: 'No orders are eligible for collection.',
              retry: () => operations.loadCollectionEligibility(selected!),
              rows: operations.collectionOrders
                  .map((order) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value:
                            operations.selectedCollectionIds.contains(order.id),
                        onChanged: (_) => operations.toggleCollection(order.id),
                        title: Text(order.id),
                        subtitle: Text(
                          '${order.status} · collect ${formatUsd(order.settlementValue)}',
                        ),
                      ))
                  .toList(),
            ),
            _ErrorText(operations.errorFor('collectionPreview') ??
                operations.errorFor('collectionCreate')),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: operations.selectedCollectionIds.isEmpty ||
                        operations.isBusy('collectionPreview') ||
                        operations.isBusy('collectionCreate')
                    ? null
                    : () => _reviewCollection(context),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review collection'),
              ),
            ),
          ],
        ],
      );

  Future<void> _scanCollection(BuildContext context) => showOrderScanner(
        context,
        title: 'Select collection orders',
        process: (orderId) async {
          final result = operations.selectCollectionByScan(orderId);
          return switch (result) {
            ScanSelectionResult.added => OrderScanResult(
                kind: ScanResultKind.valid,
                orderId: orderId,
                message: '$orderId added to this collection',
              ),
            ScanSelectionResult.alreadySelected => OrderScanResult(
                kind: ScanResultKind.alreadySelected,
                orderId: orderId,
                message: '$orderId is already selected',
              ),
            ScanSelectionResult.notEligible => OrderScanResult(
                kind: ScanResultKind.notEligible,
                orderId: orderId,
                message:
                    '$orderId is not eligible for the selected driver. Refresh if its state changed.',
              ),
          };
        },
      );

  Future<void> _reviewCollection(BuildContext context) async {
    if (!await operations.previewSelectedCollection(selected!) ||
        !context.mounted) {
      return;
    }
    final preview = operations.collectionPreview!;
    final confirmed = await _confirmSummary(
      context,
      title: 'Confirm driver collection',
      warning: 'This creates one collection and settles all selected orders.',
      rows: {
        'Driver': selected!,
        'Selected orders': '${preview.orderCount}',
        'Gross cash': formatUsd(preview.grossAmount),
        'Driver fee': formatUsd(preview.deductions),
        'Net cash to GoDelivery': formatUsd(preview.netAmount),
      },
    );
    if (confirmed != true || !context.mounted) return;
    if (await operations.createSelectedCollection(selected!) &&
        context.mounted) {
      await afterMutation();
    }
  }
}

class _PaymentPanel extends StatelessWidget {
  final List<User> merchants;
  final String? selected;
  final FinancialOperationsProvider operations;
  final ValueChanged<String?> onChanged;
  final Future<void> Function() afterMutation;

  const _PaymentPanel({
    required this.merchants,
    required this.selected,
    required this.operations,
    required this.onChanged,
    required this.afterMutation,
  });

  @override
  Widget build(BuildContext context) => _OperationCard(
        title: 'POSTPAID merchant payment',
        subtitle: 'Pay only backend-eligible collected orders',
        children: [
          _UserPicker(
              label: 'POSTPAID merchant',
              users: merchants,
              value: selected,
              onChanged: onChanged),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _SelectionList(
              loading: operations.isBusy('paymentEligibility'),
              error: operations.errorFor('paymentEligibility'),
              emptyText: 'No orders are eligible for payment.',
              retry: () => operations.loadPaymentEligibility(selected!),
              rows: operations.paymentOrders
                  .map((order) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: operations.selectedPaymentIds.contains(order.id),
                        onChanged: (_) => operations.togglePayment(order.id),
                        title: Text(order.id),
                        subtitle: Text(
                          'Payable ${formatUsd(order.settlementValue)}',
                        ),
                      ))
                  .toList(),
            ),
            _ErrorText(operations.errorFor('paymentPreview') ??
                operations.errorFor('paymentCreate')),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: operations.selectedPaymentIds.isEmpty ||
                        operations.isBusy('paymentPreview') ||
                        operations.isBusy('paymentCreate')
                    ? null
                    : () => _reviewPayment(context),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Review payment'),
              ),
            ),
          ],
        ],
      );

  Future<void> _reviewPayment(BuildContext context) async {
    if (!await operations.previewSelectedPayment(selected!) ||
        !context.mounted) {
      return;
    }
    final preview = operations.paymentPreview!;
    final confirmed = await _confirmSummary(
      context,
      title: 'Confirm POSTPAID payment',
      warning: 'All selected orders are revalidated before any write.',
      rows: {
        'Merchant': selected!,
        'Account type': 'POSTPAID',
        'Selected orders': '${preview.orderCount}',
        'Gross eligible value': formatUsd(preview.grossAmount),
        'Delivery charges': formatUsd(preview.deductions),
        'Final payable': formatUsd(preview.netAmount),
      },
    );
    if (confirmed != true || !context.mounted) return;
    if (await operations.createSelectedPayment(selected!) && context.mounted) {
      await afterMutation();
    }
  }
}

enum _AdjustmentDirection { advance, cashBack }

class _PrepaidPanel extends StatefulWidget {
  final List<User> merchants;
  final List<FinancePartyBalance> balances;
  final String? selected;
  final FinancialOperationsProvider operations;
  final ValueChanged<String?> onChanged;
  final Future<void> Function() afterMutation;

  const _PrepaidPanel({
    required this.merchants,
    required this.balances,
    required this.selected,
    required this.operations,
    required this.onChanged,
    required this.afterMutation,
  });

  @override
  State<_PrepaidPanel> createState() => _PrepaidPanelState();
}

class _PrepaidPanelState extends State<_PrepaidPanel> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  _AdjustmentDirection _direction = _AdjustmentDirection.advance;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.balances.where(
      (row) => row.username == widget.selected,
    );
    final balance = matches.isEmpty ? null : matches.first;
    return _OperationCard(
      title: 'PREPAID balance / adjustment',
      subtitle: 'Signed advances use the existing PREPAID ledger formula',
      children: [
        _UserPicker(
          label: 'PREPAID merchant',
          users: widget.merchants,
          value: widget.selected,
          onChanged: widget.onChanged,
        ),
        if (balance != null) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              Text('Entitled: ${formatUsd(balance.entitled)}'),
              Text('Paid / adjusted: ${formatUsd(balance.paid)}'),
              Text('Balance: ${formatUsd(balance.balance)}'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            balance.balance >= 0
                ? 'GoDelivery owes this merchant.'
                : 'This merchant owes GoDelivery.',
            style: context.textStyles.titleSmall,
          ),
        ],
        if (widget.selected != null) ...[
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<_AdjustmentDirection>(
            segments: const [
              ButtonSegment(
                value: _AdjustmentDirection.advance,
                label: Text('Pay merchant (+)'),
              ),
              ButtonSegment(
                value: _AdjustmentDirection.cashBack,
                label: Text('Cash back (−)'),
              ),
            ],
            selected: {_direction},
            onSelectionChanged: (value) =>
                setState(() => _direction = value.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (enter a positive magnitude)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          _ErrorText(widget.operations.errorFor('prepaidCreate')),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: widget.operations.isBusy('prepaidCreate')
                  ? null
                  : () => _submit(context),
              child: const Text('Review adjustment'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final magnitude = double.tryParse(_amount.text.trim());
    if (magnitude == null || magnitude <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount greater than zero.')),
      );
      return;
    }
    final signed =
        _direction == _AdjustmentDirection.advance ? magnitude : -magnitude;
    final meaning = _direction == _AdjustmentDirection.advance
        ? 'GoDelivery pays the merchant'
        : 'Merchant returns cash to GoDelivery';
    final confirmed = await _confirmSummary(
      context,
      title: 'Confirm PREPAID adjustment',
      warning:
          '$meaning. The sign will be ${signed < 0 ? 'negative' : 'positive'}.',
      rows: {
        'Merchant': widget.selected!,
        'Direction': meaning,
        'Signed amount': formatUsd(signed),
      },
    );
    if (confirmed != true || !context.mounted) return;
    final success = await widget.operations.createPrepaidAdjustment(
      widget.selected!,
      signed,
      notes: _notes.text.trim(),
    );
    if (!success || !context.mounted) return;
    await widget.operations.loadHistories();
    await widget.afterMutation();
    _amount.clear();
    _notes.clear();
  }
}

class _ReturnPanel extends StatelessWidget {
  final List<User> merchants;
  final String? selected;
  final FinancialOperationsProvider operations;
  final ValueChanged<String?> onChanged;
  final Future<void> Function() afterMutation;

  const _ReturnPanel({
    required this.merchants,
    required this.selected,
    required this.operations,
    required this.onChanged,
    required this.afterMutation,
  });

  @override
  Widget build(BuildContext context) => _OperationCard(
        title: 'Return goods to merchant',
        subtitle: 'Physical hand-back only; no payment record is created',
        children: [
          _UserPicker(
              label: 'Merchant',
              users: merchants,
              value: selected,
              onChanged: onChanged),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('return_scan_button'),
                onPressed: operations.isBusy('returnEligibility')
                    ? null
                    : () => _scanReturn(context),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan orders'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SelectionList(
              loading: operations.isBusy('returnEligibility'),
              error: operations.errorFor('returnEligibility'),
              emptyText: 'No goods are eligible to return.',
              retry: () => operations.loadReturnEligibility(selected!),
              rows: operations.returnableOrders
                  .map((order) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: operations.selectedReturnIds.contains(order.id),
                        onChanged: (_) => operations.toggleReturn(order.id),
                        title: Text(order.id),
                        subtitle: Text(
                          '${order.reason} · goods ${formatUsd(order.goodsValue)}',
                        ),
                      ))
                  .toList(),
            ),
            _ErrorText(operations.errorFor('returnCreate')),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: operations.selectedReturnIds.isEmpty ||
                        operations.isBusy('returnCreate')
                    ? null
                    : () => _submit(context),
                icon: const Icon(Icons.keyboard_return_rounded),
                label: const Text('Review return'),
              ),
            ),
          ],
        ],
      );

  Future<void> _scanReturn(BuildContext context) => showOrderScanner(
        context,
        title: 'Select return orders',
        process: (orderId) async {
          final result = operations.selectReturnByScan(orderId);
          return switch (result) {
            ScanSelectionResult.added => OrderScanResult(
                kind: ScanResultKind.valid,
                orderId: orderId,
                message: '$orderId added to this return',
              ),
            ScanSelectionResult.alreadySelected => OrderScanResult(
                kind: ScanResultKind.alreadySelected,
                orderId: orderId,
                message: '$orderId is already selected',
              ),
            ScanSelectionResult.notEligible => OrderScanResult(
                kind: ScanResultKind.notEligible,
                orderId: orderId,
                message:
                    '$orderId is not returnable for the selected merchant. Refresh if its state changed.',
              ),
          };
        },
      );

  Future<void> _submit(BuildContext context) async {
    final prepaid = operations.returnAccountType?.toUpperCase() == 'PREPAID';
    final confirmed = await _confirmSummary(
      context,
      title: 'Confirm goods return',
      warning: prepaid
          ? 'PREPAID cancelled orders remain cancelled. Exchanges keep their status.'
          : 'POSTPAID cancelled orders close as Paid. Exchanges keep their status.',
      rows: {
        'Merchant': selected!,
        'Account type': operations.returnAccountType ?? 'Unknown',
        'Selected orders': '${operations.selectedReturnIds.length}',
        'Money moved': formatUsd(0),
      },
    );
    if (confirmed != true || !context.mounted) return;
    if (await operations.createSelectedReturn(selected!) && context.mounted) {
      await afterMutation();
    }
  }
}

class _HistoryPanel extends StatelessWidget {
  final FinancialOperationsProvider operations;

  const _HistoryPanel({required this.operations});

  @override
  Widget build(BuildContext context) => _OperationCard(
        title: 'Settlement and return history',
        subtitle: 'Read-only audit view; reversals are not available',
        children: [
          if (operations.isBusy('history'))
            const LinearProgressIndicator()
          else if (operations.errorFor('history') != null)
            AppErrorState(
              message: operations.errorFor('history')!,
              onRetry: operations.loadHistories,
            )
          else if (operations.collectionHistory.isEmpty &&
              operations.paymentHistory.isEmpty &&
              operations.returnHistory.isEmpty)
            const AppEmptyState(
              title: 'No financial history',
              message: 'Collections, payments and returns will appear here.',
            )
          else ...[
            for (final item in operations.collectionHistory.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.move_to_inbox_outlined),
                title: Text('Collection #${item.number} · ${item.driverName}'),
                subtitle: Text(
                  '${item.orderCount} orders · gross ${formatUsd(item.amount)} · fee ${formatUsd(item.deliveryFee)}\n'
                  '${_orderIds(item.orders.map((order) => order.id))} · ${_date(item.createdAt)} · admin ${item.admin?.username ?? 'unknown'}',
                ),
                trailing: Text(formatUsd(item.amount - item.deliveryFee)),
              ),
            for (final item in operations.paymentHistory.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.payments_outlined),
                title: Text('Payment #${item.number} · ${item.merchantName}'),
                subtitle: Text(
                  '${_paymentType(item.isAdvance, item.amount)} · ${item.orderCount} orders\n'
                  '${_orderIds(item.orders.map((order) => order.id))} · ${_date(item.createdAt)} · admin ${item.admin?.username ?? 'unknown'}',
                ),
                trailing: Text(formatUsd(item.amount)),
              ),
            for (final item in operations.returnHistory.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.keyboard_return_rounded),
                title:
                    Text('Return #${item.number} · ${item.merchantUsername}'),
                subtitle: Text(
                  '${item.orderIds.length} orders · ${_orderIds(item.orderIds)}\n'
                  '${_date(item.createdAt)} · admin ${item.adminUsername}',
                ),
                trailing: Text(formatUsd(item.goodsValue)),
              ),
          ],
        ],
      );

  static String _date(DateTime value) => DateFormat.yMMMd().format(value);

  static String _orderIds(Iterable<String> ids) {
    final values = ids.where((id) => id.isNotEmpty).toList();
    return values.isEmpty ? 'No linked orders' : values.join(', ');
  }

  static String _paymentType(bool advance, double amount) {
    if (!advance) return 'POSTPAID settlement';
    return amount < 0 ? 'PREPAID cash-back' : 'PREPAID advance';
  }
}

class _OperationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _OperationCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      );
}

class _UserPicker extends StatelessWidget {
  final String label;
  final List<User> users;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _UserPicker({
    required this.label,
    required this.users,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue:
            users.any((user) => user.username == value) ? value : null,
        decoration: InputDecoration(labelText: label),
        items: users
            .map((user) => DropdownMenuItem(
                  value: user.username,
                  child: Text('${user.fullName.trim()} (${user.username})'),
                ))
            .toList(),
        onChanged: users.isEmpty ? null : onChanged,
      );
}

class _SelectionList extends StatelessWidget {
  final bool loading;
  final String? error;
  final String emptyText;
  final Future<bool> Function() retry;
  final List<Widget> rows;

  const _SelectionList({
    required this.loading,
    required this.error,
    required this.emptyText,
    required this.retry,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator();
    if (error != null) {
      return Row(children: [
        Expanded(
            child: Text(error!, style: TextStyle(color: context.colors.error))),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ]);
    }
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(emptyText),
      );
    }
    return Column(children: rows);
  }
}

class _ErrorText extends StatelessWidget {
  final String? message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(message!, style: TextStyle(color: context.colors.error)),
        );
}

Future<bool?> _confirmSummary(
  BuildContext context, {
  required String title,
  required String warning,
  required Map<String, String> rows,
}) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(warning),
              const SizedBox(height: AppSpacing.md),
              for (final entry in rows.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(children: [
                    Expanded(child: Text(entry.key)),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(entry.value, textAlign: TextAlign.end),
                    ),
                  ]),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
