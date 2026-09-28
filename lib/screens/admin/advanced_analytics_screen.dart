import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/analytics_report.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';
import '../orders/order_csv_dialog.dart';
import '../reports/statement_screen.dart';

const analyticsPresets = {
  'today': 'Today',
  'yesterday': 'Yesterday',
  'last7': 'Last 7 days',
  'last30': 'Last 30 days',
  'thisMonth': 'This month',
  'previousMonth': 'Previous month',
  'custom': 'Custom range',
};

class AdvancedAnalyticsPage extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const AdvancedAnalyticsPage({super.key, required this.onRefresh});
  @override
  State<AdvancedAnalyticsPage> createState() => _AdvancedAnalyticsPageState();
}

class _AdvancedAnalyticsPageState extends State<AdvancedAnalyticsPage> {
  bool _exporting = false;
  String _merchantSearch = '';
  String _driverSearch = '';
  String _merchantSort = 'orders';
  String _driverSort = 'orders';

  List<PartyReportRow> _sortedRows(List<PartyReportRow> rows, String sort) {
    final sorted = [...rows];
    sorted.sort((a, b) {
      final first = sort == 'delivered'
          ? a.delivered
          : sort == 'gross'
              ? a.grossUSD
              : a.orders;
      final second = sort == 'delivered'
          ? b.delivered
          : sort == 'gross'
              ? b.grossUSD
              : b.orders;
      return second.compareTo(first);
    });
    return sorted;
  }

  void _apply(AnalyticsQuery next) =>
      context.read<AnalyticsReportProvider>().load(next);

  AnalyticsQuery _copy(AnalyticsQuery query,
          {String? preset,
          String? startDate,
          String? endDate,
          String? merchantId,
          String? driverId,
          String? district,
          String? city,
          bool clearMerchant = false,
          bool clearDriver = false,
          bool clearDistrict = false,
          bool clearCity = false,
          bool clearDates = false}) =>
      AnalyticsQuery(
        preset: preset ?? query.preset,
        startDate: clearDates ? null : startDate ?? query.startDate,
        endDate: clearDates ? null : endDate ?? query.endDate,
        merchantId: clearMerchant ? null : merchantId ?? query.merchantId,
        driverId: clearDriver ? null : driverId ?? query.driverId,
        district: clearDistrict ? null : district ?? query.district,
        city: clearCity ? null : city ?? query.city,
      );

  Future<void> _chooseCustom(AnalyticsQuery query) async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)));
    if (!mounted || picked == null) return;
    final days = picked.end.difference(picked.start).inDays + 1;
    if (days > 366) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose at most 366 days.')));
      return;
    }
    _apply(_copy(query,
        preset: 'custom',
        startDate: DateFormat('yyyy-MM-dd').format(picked.start),
        endDate: DateFormat('yyyy-MM-dd').format(picked.end)));
  }

  Future<void> _export(String section, AnalyticsQuery query) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes =
          await ApiService.downloadAnalyticsCsv(query.parameters, section);
      await saveOrderCsv(
          'GoDelivery-Analytics-$section-${DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc())}.csv',
          bytes);
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
    final provider = context.watch<AnalyticsReportProvider>();
    final admin = context.watch<AdminProvider>();
    final query = provider.query;
    final report = provider.report;
    final merchants = admin.users.where((user) => user.isMerchant).toList();
    final drivers = admin.users.where((user) => user.isDriver).toList();
    final districts = admin.locations;
    final districtMatches =
        districts.where((item) => item.nameEn == query.district);
    final cities = districtMatches.isEmpty
        ? <String>[]
        : districtMatches.first.cities.map((item) => item.nameEn).toList();
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          AppPageHeader(
              title: 'Analytics',
              subtitle: 'UTC reporting · orders grouped by creation date',
              actions: [
                OutlinedButton.icon(
                    onPressed:
                        provider.loading ? null : () => widget.onRefresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh')),
                PopupMenuButton<String>(
                  tooltip: 'Export report CSV',
                  enabled: report != null && !_exporting,
                  onSelected: (section) => _export(section, query),
                  itemBuilder: (_) => [
                    for (final section in [
                      'summary',
                      'merchants',
                      'drivers',
                      'regions',
                      if (report?.finance != null) 'finance'
                    ])
                      PopupMenuItem(
                          value: section, child: Text('Export $section CSV')),
                  ],
                  child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.download_outlined)),
                ),
              ]),
          const SizedBox(height: 12),
          AppSurfaceCard(
              child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                DropdownButton<String>(
                    value: query.preset,
                    items: [
                      for (final entry in analyticsPresets.entries)
                        DropdownMenuItem(
                            value: entry.key, child: Text(entry.value)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      if (value == 'custom') {
                        _chooseCustom(query);
                        return;
                      }
                      _apply(_copy(query, preset: value, clearDates: true));
                    }),
                if (query.startDate != null)
                  Text('${query.startDate} – ${query.endDate} UTC'),
                DropdownButton<String?>(
                    value: query.merchantId,
                    hint: const Text('All merchants'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All merchants')),
                      ...merchants.map((item) => DropdownMenuItem(
                          value: item.id, child: Text(item.username)))
                    ],
                    onChanged: (value) => _apply(_copy(query,
                        merchantId: value, clearMerchant: value == null))),
                DropdownButton<String?>(
                    value: query.driverId,
                    hint: const Text('All drivers'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All drivers')),
                      ...drivers.map((item) => DropdownMenuItem(
                          value: item.id, child: Text(item.username)))
                    ],
                    onChanged: (value) => _apply(_copy(query,
                        driverId: value, clearDriver: value == null))),
                DropdownButton<String?>(
                    value: query.district,
                    hint: const Text('All districts'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All districts')),
                      ...districts.map((item) => DropdownMenuItem(
                          value: item.nameEn, child: Text(item.nameEn)))
                    ],
                    onChanged: (value) => _apply(_copy(query,
                        district: value,
                        clearDistrict: value == null,
                        clearCity: true))),
                if (query.district != null)
                  DropdownButton<String?>(
                      value: cities.contains(query.city) ? query.city : null,
                      hint: const Text('All cities'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All cities')),
                        ...cities.map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                      ],
                      onChanged: (value) => _apply(
                          _copy(query, city: value, clearCity: value == null))),
                TextButton.icon(
                    onPressed: () => _apply(const AnalyticsQuery()),
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Clear filters')),
              ])),
          if (provider.loading)
            const Padding(
                padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
          if (provider.error != null)
            AppSurfaceCard(
                child: Text(provider.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          if (report == null && !provider.loading && provider.error == null)
            const AppEmptyState(
                title: 'No report', message: 'Choose a period and refresh.'),
          if (report != null) ...[
            const SizedBox(height: 16),
            Text(
                'Selected ${report.range.startDate} to ${report.range.endDate} UTC · previous ${report.range.previousStartDate} to ${report.range.previousEndDate}',
                style: context.textStyles.bodySmall),
            const SizedBox(height: 12),
            _KpiGrid(report: report),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(
                  label: Text(
                      'Collected status: ${report.value('collectedOrders').toInt()}')),
              Chip(
                  label: Text(
                      'Paid status: ${report.value('paidOrders').toInt()}')),
              Chip(
                  label: Text(
                      'Delivery success: ${_rate(report.summary['deliverySuccessRate'])}')),
              Chip(
                  label: Text(
                      'Cancellation rate: ${_rate(report.summary['cancellationRate'])}')),
              Chip(
                  label: Text(
                      'Express rate: ${_rate(report.summary['expressRate'])}')),
            ]),
            const SizedBox(height: 16),
            AppSurfaceCard(child: _TrendChart(report: report)),
            const SizedBox(height: 16),
            AppSurfaceCard(child: _StatusSection(report: report)),
            const SizedBox(height: 16),
            AppSurfaceCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const AppSectionHeader(
                      title: 'Merchant performance',
                      subtitle: 'Factual order activity and recorded payments'),
                  TextField(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search merchant'),
                      onChanged: (value) => setState(
                          () => _merchantSearch = value.toLowerCase())),
                  DropdownButton<String>(
                      value: _merchantSort,
                      items: const [
                        DropdownMenuItem(
                            value: 'orders', child: Text('Sort: orders')),
                        DropdownMenuItem(
                            value: 'delivered', child: Text('Sort: delivered')),
                        DropdownMenuItem(
                            value: 'gross', child: Text('Sort: eligible gross'))
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _merchantSort = value);
                        }
                      }),
                  _PartyList(
                      rows: _sortedRows(
                          report.merchants
                              .where((row) => row.name
                                  .toLowerCase()
                                  .contains(_merchantSearch))
                              .toList(),
                          _merchantSort),
                      kind: 'merchant'),
                ])),
            const SizedBox(height: 16),
            AppSurfaceCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const AppSectionHeader(
                      title: 'Driver performance',
                      subtitle: 'Assigned orders and recorded collections'),
                  TextField(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search driver'),
                      onChanged: (value) =>
                          setState(() => _driverSearch = value.toLowerCase())),
                  DropdownButton<String>(
                      value: _driverSort,
                      items: const [
                        DropdownMenuItem(
                            value: 'orders', child: Text('Sort: orders')),
                        DropdownMenuItem(
                            value: 'delivered', child: Text('Sort: delivered')),
                        DropdownMenuItem(
                            value: 'gross', child: Text('Sort: eligible gross'))
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _driverSort = value);
                      }),
                  _PartyList(
                      rows: _sortedRows(
                          report.drivers
                              .where((row) => row.name
                                  .toLowerCase()
                                  .contains(_driverSearch))
                              .toList(),
                          _driverSort),
                      kind: 'driver'),
                ])),
            const SizedBox(height: 16),
            AppSurfaceCard(child: _RegionSection(report: report)),
            const SizedBox(height: 16),
            AppSurfaceCard(child: _FinanceSection(report: report)),
          ],
        ],
      ),
    );
  }

  String _rate(double? value) =>
      value == null ? 'n/a' : '${(value * 100).toStringAsFixed(1)}%';
}

class _KpiGrid extends StatelessWidget {
  final AnalyticsReport report;
  const _KpiGrid({required this.report});
  @override
  Widget build(BuildContext context) {
    const metrics = [
      ('totalOrders', 'Orders created', false),
      ('deliveredOrders', 'Delivered outcome', false),
      ('cancelledOrders', 'Cancelled outcome', false),
      ('activeOrders', 'Active orders', false),
      ('grossOrderValueUSD', 'Eligible gross value', true),
      ('deliveryChargesUSD', 'Eligible delivery charges', true),
      ('averageOrderValueUSD', 'Average eligible order', true),
      ('expressOrders', 'Express orders', false),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 540
              ? 2
              : 1;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final (key, title, money) in metrics)
          SizedBox(
              width: width,
              child: AppSurfaceCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title, style: context.textStyles.labelLarge),
                    const SizedBox(height: 5),
                    Text(
                        money
                            ? formatUsd(report.value(key))
                            : report.value(key).toInt().toString(),
                        style: context.textStyles.headlineSmall),
                    Text(_comparison(report.comparison[key]),
                        style: context.textStyles.bodySmall),
                  ]))),
      ]);
    });
  }

  String _comparison(MetricComparison? value) {
    if (value == null) return 'No comparison';
    final change = value.change >= 0
        ? '+${value.change.toStringAsFixed(1)}'
        : value.change.toStringAsFixed(1);
    final percent = value.percentChange == null
        ? 'n/a (previous 0)'
        : '${value.percentChange!.toStringAsFixed(1)}%';
    return '$change · $percent vs previous period';
  }
}

class _TrendChart extends StatelessWidget {
  final AnalyticsReport report;
  const _TrendChart({required this.report});
  @override
  Widget build(BuildContext context) {
    final points = report.trend;
    final maxValue = points.fold<int>(
        1, (max, point) => point.orders > max ? point.orders : max);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppSectionHeader(
          title: 'Order trend',
          subtitle:
              'Created orders by ${report.trendBucket}; outcome counts are in the CSV'),
      if (points.isEmpty)
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No order activity in this period.')),
      if (points.isNotEmpty)
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final point in points)
                SizedBox(
                    width: 48,
                    child: Column(children: [
                      Text('${point.orders}',
                          style: context.textStyles.bodySmall),
                      SizedBox(
                          height: 130,
                          child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                  width: 26,
                                  height: 120 * point.orders / maxValue,
                                  decoration: BoxDecoration(
                                      color: AppColors.blue,
                                      borderRadius:
                                          BorderRadius.circular(4))))),
                      const SizedBox(height: 4),
                      Text(
                          point.period
                              .substring(point.period.length > 7 ? 5 : 0),
                          maxLines: 1,
                          style: context.textStyles.bodySmall),
                    ])),
            ])),
      if (points.isNotEmpty)
        const Text(
            'Blue bars: orders created. Delivered/cancelled counts are in the report CSV.'),
    ]);
  }
}

class _StatusSection extends StatelessWidget {
  final AnalyticsReport report;
  const _StatusSection({required this.report});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppSectionHeader(
            title: 'Raw current status',
            subtitle: 'Separate from delivered/cancelled business outcomes'),
        for (final entry in report.statuses.entries)
          ListTile(
              dense: true,
              title: Text(entry.key),
              trailing: Text('${entry.value}')),
      ]);
}

class _PartyList extends StatelessWidget {
  final List<PartyReportRow> rows;
  final String kind;
  const _PartyList({required this.rows, required this.kind});
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No activity in this period.'));
    }
    return Column(children: [
      for (final row in rows.take(20))
        ListTile(
          title: Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(kind == 'driver'
              ? '${row.orders} assigned · ${row.pickedUpStatus} currently picked up · ${row.delivered} delivered · ${row.customerCancellations} customer / ${row.merchantCancellations} merchant cancellations'
              : '${row.orders} orders · ${row.delivered} delivered · ${row.cancelled} cancelled · ${formatUsd(row.grossUSD)} eligible gross'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StatementScreen(kind: kind, id: row.id))),
        ),
      if (rows.length > 20)
        Text('${rows.length - 20} more rows are available in CSV.'),
    ]);
  }
}

class _RegionSection extends StatelessWidget {
  final AnalyticsReport report;
  const _RegionSection({required this.report});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppSectionHeader(
            title: 'Regional activity',
            subtitle: 'Existing district and city values; no map or geocoding'),
        if (report.districts.isEmpty)
          const Text('No regional activity in this period.'),
        for (final row in report.districts.take(10))
          ListTile(
              dense: true,
              title: Text(row.name),
              subtitle: Text(
                  '${row.delivered} delivered · ${row.cancelled} cancelled'),
              trailing: Text('${row.orders} orders')),
        if (report.cities.isNotEmpty)
          ExpansionTile(title: const Text('Cities'), children: [
            for (final row in report.cities.take(20))
              ListTile(
                  dense: true,
                  title: Text(row.name),
                  trailing: Text('${row.orders}'))
          ]),
      ]);
}

class _FinanceSection extends StatelessWidget {
  final AnalyticsReport report;
  const _FinanceSection({required this.report});
  @override
  Widget build(BuildContext context) {
    final finance = report.finance;
    if (finance == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppSectionHeader(title: 'Company finance'),
        Text(report.financeScope)
      ]);
    }
    double number(String key) => (finance[key] as num?)?.toDouble() ?? 0;
    String comparison(String key) {
      final values = Map<String, dynamic>.from(
          (finance['comparison'] as Map?)?[key] as Map? ?? {});
      final percent = (values['percentChange'] as num?)?.toDouble();
      return percent == null
          ? 'n/a vs previous'
          : '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}% vs previous';
    }

    final expenses =
        Map<String, dynamic>.from(finance['expenseCategories'] as Map? ?? {});
    final methods =
        Map<String, dynamic>.from(finance['paymentMethods'] as Map? ?? {});
    final expenseTrend = (finance['expenseTrend'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final cashTrend = (finance['cashTrend'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final maxCash = cashTrend.fold<double>(1, (max, item) {
      final incoming = (item['cashInUSD'] as num?)?.toDouble() ?? 0;
      final outgoing = (item['cashOutUSD'] as num?)?.toDouble() ?? 0;
      return [max, incoming, outgoing].reduce((a, b) => a > b ? a : b);
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const AppSectionHeader(
          title: 'Company finance',
          subtitle:
              'Recorded completed transactions; net cash movement is not profit'),
      Text(
          'Cash in: ${formatUsd(number('cashInUSD'))}   Cash out: ${formatUsd(number('cashOutUSD'))}'),
      Text(
          'Cash in ${comparison('cashInUSD')} · cash out ${comparison('cashOutUSD')}'),
      Text('Net cash movement: ${formatUsd(number('netCashMovementUSD'))}'),
      Text('Net movement ${comparison('netCashMovementUSD')}'),
      const SizedBox(height: 12),
      const Text('Cash movement by recorded date · blue in / amber out'),
      if (cashTrend.isEmpty)
        const Text('No completed transactions in this period.'),
      if (cashTrend.isNotEmpty)
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final point in cashTrend)
                SizedBox(
                    width: 54,
                    child: Column(children: [
                      SizedBox(
                          height: 110,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                    width: 16,
                                    height: 100 *
                                        ((point['cashInUSD'] as num?)
                                                ?.toDouble() ??
                                            0) /
                                        maxCash,
                                    color: AppColors.blue),
                                const SizedBox(width: 3),
                                Container(
                                    width: 16,
                                    height: 100 *
                                        ((point['cashOutUSD'] as num?)
                                                ?.toDouble() ??
                                            0) /
                                        maxCash,
                                    color: AppColors.amber),
                              ])),
                      Text(point['period']?.toString().substring(5) ?? '',
                          style: context.textStyles.bodySmall),
                    ])),
            ])),
      Text(
          'Collections: ${formatUsd(number('collectionGrossUSD'))} gross · ${formatUsd(number('collectionDriverFeeUSD'))} recorded driver fees'),
      Text(
          'Merchant payments: ${formatUsd(number('merchantPaymentsUSD'))} · expenses: ${formatUsd(number('expensesUSD'))}'),
      const SizedBox(height: 8),
      Text(
          'Completed transaction volume by method: ${methods.entries.map((entry) => '${entry.key} ${formatUsd((entry.value as num).toDouble())}').join(' · ')}'),
      if (expenses.isEmpty) const Text('No recorded expenses in this period.'),
      for (final entry in expenses.entries)
        ListTile(
            dense: true,
            title: Text(entry.key),
            trailing: Text(formatUsd((entry.value as num).toDouble()))),
      if (expenseTrend.isNotEmpty)
        ExpansionTile(title: const Text('Expense trend by date'), children: [
          for (final point in expenseTrend)
            ListTile(
                dense: true,
                title: Text(point['period']?.toString() ?? ''),
                trailing: Text(
                    formatUsd((point['amountUSD'] as num?)?.toDouble() ?? 0))),
        ]),
    ]);
  }
}
