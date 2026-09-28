import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/analytics_report.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';
import '../orders/order_csv_dialog.dart';

class StatementScreen extends StatefulWidget {
  final String kind;
  final String? id;
  const StatementScreen({super.key, required this.kind, this.id});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  String _preset = 'last30';
  String? _startDate;
  String? _endDate;
  StatementReport? _statement;
  String? _error;
  bool _loading = false;
  bool _exporting = false;
  int _generation = 0;

  Map<String, String> get _filters => _startDate == null
      ? {'preset': _preset}
      : {'startDate': _startDate!, 'endDate': _endDate!};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _statement = null;
    });
    try {
      final result = await ApiService.getStatement(
          kind: widget.kind, id: widget.id, filters: _filters);
      if (!mounted || generation != _generation) return;
      if (result['success'] != true || result['data'] is! Map) {
        throw ApiException(
            result['error']?.toString() ?? 'Statement unavailable');
      }
      setState(() => _statement = StatementReport.fromJson(
          Map<String, dynamic>.from(result['data'] as Map)));
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _customRange() async {
    final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)));
    if (selected == null || !mounted) return;
    if (selected.end.difference(selected.start).inDays >= 366) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose at most 366 days.')));
      return;
    }
    _startDate = DateFormat('yyyy-MM-dd').format(selected.start);
    _endDate = DateFormat('yyyy-MM-dd').format(selected.end);
    _preset = 'custom';
    _load();
  }

  Future<void> _export(String format) async {
    if (_exporting || _statement == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ApiService.downloadStatement(
          kind: widget.kind, id: widget.id, format: format, filters: _filters);
      final date = _statement!.endDate;
      await saveReportFile(
          'GoDelivery-${widget.kind}-statement-$date.$format', bytes,
          mimeType: format == 'pdf' ? 'application/pdf' : 'text/csv');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statement = _statement;
    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${widget.kind == 'merchant' ? 'Merchant' : 'Driver'} statement')),
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(context.pagePadding),
                children: [
                  AppSurfaceCard(
                      child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                        DropdownButton<String>(
                            value: _preset,
                            items: const [
                              DropdownMenuItem(
                                  value: 'today', child: Text('Today')),
                              DropdownMenuItem(
                                  value: 'yesterday', child: Text('Yesterday')),
                              DropdownMenuItem(
                                  value: 'last7', child: Text('Last 7 days')),
                              DropdownMenuItem(
                                  value: 'last30', child: Text('Last 30 days')),
                              DropdownMenuItem(
                                  value: 'thisMonth',
                                  child: Text('This month')),
                              DropdownMenuItem(
                                  value: 'previousMonth',
                                  child: Text('Previous month')),
                              DropdownMenuItem(
                                  value: 'custom', child: Text('Custom range')),
                            ],
                            onChanged: (value) {
                              if (value == 'custom') {
                                _customRange();
                                return;
                              }
                              if (value == null) return;
                              setState(() {
                                _preset = value;
                                _startDate = null;
                                _endDate = null;
                              });
                              _load();
                            }),
                        if (_startDate != null)
                          Text('$_startDate – $_endDate UTC'),
                        OutlinedButton.icon(
                            onPressed: _loading ? null : _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh')),
                        OutlinedButton.icon(
                            onPressed: statement == null || _exporting
                                ? null
                                : () => _export('csv'),
                            icon: const Icon(Icons.table_view),
                            label: const Text('CSV')),
                        OutlinedButton.icon(
                            onPressed: statement == null || _exporting
                                ? null
                                : () => _export('pdf'),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('PDF')),
                      ])),
                  if (_loading)
                    const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator()),
                  if (_error != null)
                    AppSurfaceCard(
                        child: Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  if (statement != null) ...[
                    const SizedBox(height: 12),
                    AppSurfaceCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(statement.name,
                              style: context.textStyles.titleLarge),
                          Text(
                              '${statement.username}${statement.accountType == null ? '' : ' · ${statement.accountType}'}'),
                          Text(
                              '${statement.startDate} to ${statement.endDate} UTC'),
                          const SizedBox(height: 8),
                          Text(
                              '${statement.summary['totalOrders']?.toInt() ?? 0} orders created · ${statement.summary['deliveredOrders']?.toInt() ?? 0} delivered outcome · ${statement.summary['cancelledOrders']?.toInt() ?? 0} cancelled outcome'),
                          if (widget.kind == 'merchant')
                            Text(
                                'Recorded payments: ${formatUsd(statement.activityTotals['recordedPaymentsUSD'] ?? 0)}'),
                          if (widget.kind == 'driver')
                            Text(
                                'Collections: ${formatUsd(statement.activityTotals['collectionGrossUSD'] ?? 0)} gross · ${formatUsd(statement.activityTotals['recordedDriverFeesUSD'] ?? 0)} recorded fees · ${formatUsd(statement.activityTotals['netTransferredUSD'] ?? 0)} net transferred'),
                          const Text(
                              'Current balance is a separate live snapshot; this period has no inferred opening balance.'),
                        ])),
                    const SizedBox(height: 12),
                    AppSurfaceCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const AppSectionHeader(title: 'Order activity'),
                          if (statement.orders.isEmpty)
                            const Text('No orders in this period.'),
                          for (final order in statement.orders.take(500))
                            ListTile(
                                dense: true,
                                title: Text(order['id']?.toString() ?? ''),
                                subtitle: Text(
                                    '${order['createdAt']?.toString().substring(0, 10)} · ${order['status']}'),
                                trailing: Text(formatUsd(
                                    (order['total'] as num?)?.toDouble() ??
                                        0))),
                          if (statement.orders.length > 500)
                            Text(
                                '${statement.orders.length - 500} more rows are available in CSV.'),
                        ])),
                    const SizedBox(height: 12),
                    AppSurfaceCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          AppSectionHeader(
                              title: widget.kind == 'merchant'
                                  ? 'Payments and adjustments'
                                  : 'Collections'),
                          if (statement.activity.isEmpty)
                            const Text('No recorded activity in this period.'),
                          for (final item in statement.activity.take(500))
                            ListTile(
                                dense: true,
                                title: Text(
                                    '#${item['number']} · ${item['type'] ?? 'Recorded collection'}'),
                                subtitle: Text(
                                    '${item['date']?.toString().substring(0, 10)} · ${(item['orderIds'] as List? ?? const []).length} linked orders'),
                                trailing: Text(formatUsd(
                                    (item['amountUSD'] as num?)?.toDouble() ??
                                        (item['grossUSD'] as num?)
                                            ?.toDouble() ??
                                        0))),
                          if (statement.activity.length > 500)
                            Text(
                                '${statement.activity.length - 500} more rows are available in CSV.'),
                        ])),
                  ],
                ],
              ))),
    );
  }
}
