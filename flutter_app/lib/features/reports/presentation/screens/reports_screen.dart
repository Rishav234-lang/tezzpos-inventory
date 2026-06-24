import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

class _ReportType {
  final String label;
  final IconData icon;
  final List<_SubReport> subReports;
  const _ReportType(this.label, this.icon, this.subReports);
}

class _SubReport {
  final String label;
  final String endpoint;
  const _SubReport(this.label, this.endpoint);
}

final _reportTypes = [
  _ReportType('Sales', Icons.point_of_sale, [
    _SubReport('Daily', ApiConstants.reportSalesDaily),
    _SubReport('Monthly', ApiConstants.reportSalesMonthly),
    _SubReport('Customer-wise', ApiConstants.reportSalesCustomer),
    _SubReport('Product-wise', ApiConstants.reportSalesProduct),
  ]),
  _ReportType('Purchases', Icons.shopping_cart, [
    _SubReport('Vendor-wise', ApiConstants.reportPurchaseVendor),
    _SubReport('Product-wise', ApiConstants.reportPurchaseProduct),
  ]),
  _ReportType('Inventory', Icons.inventory, [
    _SubReport('Stock', ApiConstants.reportInventoryStock),
    _SubReport('Expiry', ApiConstants.reportInventoryExpiry),
  ]),
  _ReportType('Financial', Icons.account_balance, [
    _SubReport('Profit & Loss', ApiConstants.reportFinancialProfit),
  ]),
];

final reportDataProvider = FutureProvider.autoDispose.family<dynamic, Map<String, String>>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final endpoint = params['endpoint']!;
  final queryParams = Map<String, String>.from(params)..remove('endpoint');
  final response = await api.get(endpoint, queryParams: queryParams);
  return response.data;
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedType = 0;
  int _selectedSub = 0;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final report = _reportTypes[_selectedType];
    final subReport = report.subReports[_selectedSub];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_dateRange != null ? '${_fmt(_dateRange!.start)} - ${_fmt(_dateRange!.end)}' : 'Date Range'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _exportCsv(subReport.endpoint),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export CSV'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isWide
          ? Row(children: [_buildSidebar(report), Expanded(child: _buildContent(subReport))])
          : Column(children: [_buildChips(report), Expanded(child: _buildContent(subReport))]),
    );
  }

  Widget _buildSidebar(_ReportType active) {
    return SizedBox(
      width: 220,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: ListView(
          children: [
            for (int i = 0; i < _reportTypes.length; i++) ...[
              ListTile(
                leading: Icon(_reportTypes[i].icon, size: 20, color: _selectedType == i ? AppColors.primary : null),
                title: Text(_reportTypes[i].label, style: TextStyle(fontWeight: _selectedType == i ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
                selected: _selectedType == i,
                onTap: () => setState(() { _selectedType = i; _selectedSub = 0; }),
              ),
              if (_selectedType == i)
                for (int j = 0; j < _reportTypes[i].subReports.length; j++)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: ListTile(
                      dense: true,
                      title: Text(_reportTypes[i].subReports[j].label, style: TextStyle(fontSize: 12, fontWeight: _selectedSub == j ? FontWeight.w600 : FontWeight.normal)),
                      selected: _selectedSub == j,
                      onTap: () => setState(() => _selectedSub = j),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChips(_ReportType active) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < _reportTypes.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_reportTypes[i].label),
                selected: _selectedType == i,
                onSelected: (_) => setState(() { _selectedType = i; _selectedSub = 0; }),
              ),
            ),
          const SizedBox(width: 8),
          for (int j = 0; j < _reportTypes[_selectedType].subReports.length; j++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_reportTypes[_selectedType].subReports[j].label),
                selected: _selectedSub == j,
                onSelected: (_) => setState(() => _selectedSub = j),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(_SubReport sub) {
    final params = <String, String>{'endpoint': sub.endpoint};
    if (_dateRange != null) {
      params['startDate'] = _dateRange!.start.toIso8601String();
      params['endDate'] = _dateRange!.end.toIso8601String();
    }
    final dataAsync = ref.watch(reportDataProvider(params));

    return dataAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(reportDataProvider)),
      data: (data) {
        if (data == null) return const AppEmptyState(message: 'No data for this report', icon: Icons.assessment_outlined);
        if (data is List) return _buildDataTable(data);
        if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) return _buildDataTable(data['data'] as List);
          return _buildSummaryCards(data);
        }
        return SingleChildScrollView(padding: const EdgeInsets.all(16), child: SelectableText(data.toString()));
      },
    );
  }

  Widget _buildDataTable(List items) {
    if (items.isEmpty) return const AppEmptyState(message: 'No data', icon: Icons.assessment_outlined);
    final first = items.first;
    if (first is! Map) return SingleChildScrollView(padding: const EdgeInsets.all(16), child: SelectableText(items.toString()));
    final columns = (first as Map<String, dynamic>).keys.where((k) => k != 'id' && k != 'companyId').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(AppColors.primary.withOpacity(0.05)),
          columns: columns.map((c) => DataColumn(label: Text(c.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)))).toList(),
          rows: items.map((item) {
            final row = item as Map<String, dynamic>;
            return DataRow(cells: columns.map((c) {
              final val = row[c];
              return DataCell(Text('${val ?? ''}', style: const TextStyle(fontSize: 12)));
            }).toList());
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16, runSpacing: 16,
        children: data.entries.where((e) => e.key != 'id' && e.key != 'companyId').map((e) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text('${e.value}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  Future<void> _exportCsv(String endpoint) async {
    try {
      final api = ref.read(apiClientProvider);
      final params = <String, String>{'format': 'csv'};
      if (_dateRange != null) {
        params['startDate'] = _dateRange!.start.toIso8601String();
        params['endDate'] = _dateRange!.end.toIso8601String();
      }
      await api.get(endpoint, queryParams: params);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV export triggered')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e'), backgroundColor: AppColors.error));
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
