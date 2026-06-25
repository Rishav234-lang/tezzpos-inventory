import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';

final customerDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.customers}/$id');
  return response.data as Map<String, dynamic>;
});

final customerSalesProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.customers}/$id/sales', queryParams: {'page': '1', 'limit': '100'});
  return response.data as Map<String, dynamic>;
});

final customerLedgerProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.customers}/$id/ledger');
  return response.data as Map<String, dynamic>;
});

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: customerAsync.when(
          data: (c) => Text(c['name'] ?? 'Customer Details'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Customer Details'),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer',
            onPressed: () => context.push('/customers/${widget.customerId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(customerDetailProvider(widget.customerId));
              ref.invalidate(customerSalesProvider(widget.customerId));
              ref.invalidate(customerLedgerProvider(widget.customerId));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
            Tab(icon: Icon(Icons.point_of_sale_outlined), text: 'Sales'),
            Tab(icon: Icon(Icons.account_balance_outlined), text: 'Ledger'),
          ],
        ),
      ),
      body: customerAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(customerDetailProvider(widget.customerId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        )),
        data: (customer) => TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(customer: customer, customerId: widget.customerId),
            _SalesTab(customerId: widget.customerId, onToSale: (id) => context.push('/sales/$id')),
            _LedgerTab(customerId: widget.customerId),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Map<String, dynamic> customer;
  final String customerId;
  const _OverviewTab({required this.customer, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (customer['gstNumber'] != null) Text('GST: ${customer['gstNumber']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(Icons.phone_outlined, 'Mobile', customer['mobile'] ?? '-'),
                  _infoRow(Icons.email_outlined, 'Email', customer['email'] ?? '-'),
                  _infoRow(Icons.location_on_outlined, 'Address', customer['address'] ?? '-'),
                  if (customer['city'] != null) _infoRow(Icons.location_city_outlined, 'City', '${customer['city']}${customer['state'] != null ? ', ${customer['state']}' : ''}'),
                  if (customer['pincode'] != null) _infoRow(Icons.pin_drop_outlined, 'Pincode', customer['pincode']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ledgerAsync.when(
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (ledger) {
              final total = ledger['totalSalesAmount'] ?? 0;
              final paid = ledger['totalPaidAmount'] ?? 0;
              final outstanding = ledger['outstandingBalance'] ?? 0;

              return Row(
                children: [
                  Expanded(child: _summaryCard('Total Sales', '₹${_fmtAmt(total)}', AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _summaryCard('Total Paid', '₹${_fmtAmt(paid)}', AppColors.success)),
                  const SizedBox(width: 8),
                  Expanded(child: _summaryCard('Outstanding', '₹${_fmtAmt(outstanding)}', outstanding > 0 ? AppColors.error : AppColors.success)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: color, width: 3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _fmtAmt(dynamic val) {
    if (val == null) return '0';
    if (val is num) return val.toStringAsFixed(0);
    final d = double.tryParse(val.toString()) ?? 0;
    return d.toStringAsFixed(0);
  }
}

class _SalesTab extends ConsumerWidget {
  final String customerId;
  final void Function(String saleId) onToSale;
  const _SalesTab({required this.customerId, required this.onToSale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(customerSalesProvider(customerId));

    return salesAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(customerSalesProvider(customerId))),
      data: (result) {
        final sales = (result['data'] as List<dynamic>?) ?? [];
        if (sales.isEmpty) return const AppEmptyState(message: 'No sales yet', icon: Icons.point_of_sale_outlined);

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sales.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final s = sales[index];
            final total = s['totalAmount'] is num ? (s['totalAmount'] as num).toDouble() : double.tryParse(s['totalAmount']?.toString() ?? '0') ?? 0;
            final paid = s['paidAmount'] is num ? (s['paidAmount'] as num).toDouble() : double.tryParse(s['paidAmount']?.toString() ?? '0') ?? 0;
            final balance = total - paid;
            final status = s['status'] ?? 'UNPAID';

            return Card(
              child: InkWell(
                onTap: () => onToSale(s['id']),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['invoiceNumber'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('Date: ${_fmtDate(s['invoiceDate'])}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == 'PAID' ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status == 'PAID' ? AppColors.success : AppColors.warning)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _amtChip('Total', '₹${total.toStringAsFixed(0)}', AppColors.primary),
                          const SizedBox(width: 6),
                          _amtChip('Paid', '₹${paid.toStringAsFixed(0)}', AppColors.success),
                          const SizedBox(width: 6),
                          _amtChip('Due', '₹${balance.toStringAsFixed(0)}', balance > 0 ? AppColors.error : AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _amtChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d)); } catch (_) { return d.substring(0, 10); }
  }
}

class _LedgerTab extends ConsumerWidget {
  final String customerId;
  const _LedgerTab({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));

    return ledgerAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(customerLedgerProvider(customerId))),
      data: (ledger) {
        final sales = (ledger['sales'] as List<dynamic>?) ?? [];
        final payments = (ledger['payments'] as List<dynamic>?) ?? [];

        final entries = <Map<String, dynamic>>[];
        for (final s in sales) {
          entries.add({
            ...s as Map<String, dynamic>,
            'type': 'SALE',
            'date': s['invoiceDate'] ?? s['createdAt'] ?? '',
            'amount': s['totalAmount'] ?? 0,
          });
        }
        for (final p in payments) {
          entries.add({
            ...p as Map<String, dynamic>,
            'type': 'PAYMENT',
            'date': p['paymentDate'] ?? p['createdAt'] ?? '',
            'amount': p['amount'] ?? 0,
          });
        }
        entries.sort((a, b) {
          try { return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])); } catch (_) { return 0; }
        });

        double running = 0;
        final displayEntries = <Map<String, dynamic>>[];
        for (final e in entries.reversed) {
          final isSale = e['type'] == 'SALE';
          running += (isSale ? 1 : -1) * _toDouble(e['amount']);
          displayEntries.insert(0, {...e, 'balance': running});
        }

        if (displayEntries.isEmpty) return const AppEmptyState(message: 'No ledger entries', icon: Icons.account_balance_outlined);

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: displayEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final e = displayEntries[index];
            final isSale = e['type'] == 'SALE';
            final amount = _toDouble(e['amount']);
            final balance = _toDouble(e['balance']);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSale ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  child: Icon(isSale ? Icons.point_of_sale : Icons.payment, size: 18, color: isSale ? AppColors.error : AppColors.success),
                ),
                title: Text(
                  isSale ? 'Sale: ${e['invoiceNumber'] ?? 'N/A'}' : 'Payment: ${e['paymentMode'] ?? 'Cash'}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(_fmtDate(e['date']), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${isSale ? '+' : '-'}₹${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isSale ? AppColors.error : AppColors.success)),
                    Text('Bal: ₹${balance.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _toDouble(dynamic val, {double fallback = 0}) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d)); } catch (_) { return d.substring(0, 10); }
  }
}

class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const AppEmptyState({super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AppErrorWidget({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}
