import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';

final vendorDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.vendors}/$id');
  return response.data as Map<String, dynamic>;
});

final vendorPurchasesProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.vendors}/$id/purchases', queryParams: {'page': '1', 'limit': '100'});
  return response.data as Map<String, dynamic>;
});

final vendorLedgerProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.vendors}/$id/ledger');
  return response.data as Map<String, dynamic>;
});

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> with SingleTickerProviderStateMixin {
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
    final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId));

    return Scaffold(
      appBar: AppBar(
        title: vendorAsync.when(
          data: (v) => Text(v['name'] ?? 'Vendor Details'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Vendor Details'),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Vendor',
            onPressed: () => context.go('/vendors/${widget.vendorId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(vendorDetailProvider(widget.vendorId));
              ref.invalidate(vendorPurchasesProvider(widget.vendorId));
              ref.invalidate(vendorLedgerProvider(widget.vendorId));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
            Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Purchases'),
            Tab(icon: Icon(Icons.account_balance_outlined), text: 'Ledger'),
          ],
        ),
      ),
      body: vendorAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(vendorDetailProvider(widget.vendorId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        )),
        data: (vendor) => TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(vendor: vendor, vendorId: widget.vendorId),
            _PurchasesTab(vendorId: widget.vendorId, onToPurchase: (id) => context.go('/purchases/$id')),
            _LedgerTab(vendorId: widget.vendorId),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  final Map<String, dynamic> vendor;
  final String vendorId;
  const _OverviewTab({required this.vendor, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(vendorLedgerProvider(vendorId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vendor Info Card
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
                        child: const Icon(Icons.business, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vendor['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (vendor['gstNumber'] != null) Text('GST: ${vendor['gstNumber']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(Icons.phone_outlined, 'Mobile', vendor['mobile'] ?? '-'),
                  _infoRow(Icons.email_outlined, 'Email', vendor['email'] ?? '-'),
                  _infoRow(Icons.location_on_outlined, 'Address', vendor['address'] ?? '-'),
                  if (vendor['city'] != null) _infoRow(Icons.location_city_outlined, 'City', '${vendor['city']}${vendor['state'] != null ? ', ${vendor['state']}' : ''}'),
                  if (vendor['pincode'] != null) _infoRow(Icons.pin_drop_outlined, 'Pincode', vendor['pincode']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial Summary
          ledgerAsync.when(
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (ledger) {
              final total = ledger['totalPurchaseAmount'] ?? 0;
              final paid = ledger['totalPaidAmount'] ?? 0;
              final outstanding = ledger['outstandingBalance'] ?? 0;

              return Row(
                children: [
                  Expanded(child: _summaryCard('Total Purchases', '₹${_fmtAmt(total)}', AppColors.primary)),
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

// ─── Purchases Tab ──────────────────────────────────────────────
class _PurchasesTab extends ConsumerWidget {
  final String vendorId;
  final void Function(String purchaseId) onToPurchase;
  const _PurchasesTab({required this.vendorId, required this.onToPurchase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(vendorPurchasesProvider(vendorId));

    return purchasesAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(vendorPurchasesProvider(vendorId))),
      data: (result) {
        final purchases = (result['data'] as List<dynamic>?) ?? [];
        if (purchases.isEmpty) return const AppEmptyState(message: 'No purchases yet', icon: Icons.shopping_cart_outlined);

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: purchases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final p = purchases[index];
            final total = p['totalAmount'] is num ? (p['totalAmount'] as num).toDouble() : double.tryParse(p['totalAmount']?.toString() ?? '0') ?? 0;
            final paid = p['paidAmount'] is num ? (p['paidAmount'] as num).toDouble() : double.tryParse(p['paidAmount']?.toString() ?? '0') ?? 0;
            final balance = total - paid;
            final status = p['status'] ?? 'UNPAID';
            final items = (p['items'] as List<dynamic>?) ?? [];
            final batches = (p['batches'] as List<dynamic>?) ?? [];

            return Card(
              child: InkWell(
                onTap: () => onToPurchase(p['id']),
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
                                Text(p['invoiceNumber'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('Date: ${_fmtDate(p['purchaseDate'])}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
                      if (items.isNotEmpty) ...[
                        const Divider(height: 16),
                        ...items.map((item) {
                          final product = item['product'] as Map<String, dynamic>?;
                          final qty = item['quantity'] ?? 0;
                          final price = item['purchasePrice'] ?? 0;
                          final itemTotal = item['totalAmount'] ?? (qty * price);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                      Text('SKU: ${product?['sku'] ?? '-'}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Text('$qty x ₹$price', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                const SizedBox(width: 8),
                                Text('₹$itemTotal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ],
                      if (batches.isNotEmpty) ...[
                        const Divider(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: batches.map<Widget>((b) {
                            final expiry = (b['expiryDate'] ?? '').toString();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                'Batch: ${b['batchNumber']} • Avail: ${b['availableQuantity']}${expiry.length >= 10 ? ' • Exp: ${expiry.substring(0, 10)}' : ''}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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

// ─── Ledger Tab ─────────────────────────────────────────────────
class _LedgerTab extends ConsumerWidget {
  final String vendorId;
  const _LedgerTab({required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(vendorLedgerProvider(vendorId));

    return ledgerAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(vendorLedgerProvider(vendorId))),
      data: (ledger) {
        final purchases = (ledger['purchases'] as List<dynamic>?) ?? [];
        final payments = (ledger['payments'] as List<dynamic>?) ?? [];

        // Merge and sort by date
        final entries = <Map<String, dynamic>>[];
        for (final p in purchases) {
          entries.add({
            ...p as Map<String, dynamic>,
            'type': 'PURCHASE',
            'date': p['purchaseDate'] ?? p['createdAt'] ?? '',
            'amount': p['totalAmount'] ?? 0,
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

        // Compute running balance
        double running = 0;
        final displayEntries = <Map<String, dynamic>>[];
        for (final e in entries.reversed) {
          final isPurchase = e['type'] == 'PURCHASE';
          running += (isPurchase ? 1 : -1) * _toDouble(e['amount']);
          displayEntries.insert(0, {...e, 'balance': running});
        }

        if (displayEntries.isEmpty) return const AppEmptyState(message: 'No ledger entries', icon: Icons.account_balance_outlined);

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: displayEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final e = displayEntries[index];
            final isPurchase = e['type'] == 'PURCHASE';
            final amount = _toDouble(e['amount']);
            final balance = _toDouble(e['balance']);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPurchase ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  child: Icon(isPurchase ? Icons.shopping_cart : Icons.payment, size: 18, color: isPurchase ? AppColors.error : AppColors.success),
                ),
                title: Text(
                  isPurchase ? 'Purchase: ${e['invoiceNumber'] ?? 'N/A'}' : 'Payment: ${e['paymentMode'] ?? 'Cash'}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(_fmtDate(e['date']), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${isPurchase ? '+' : '-'}₹${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isPurchase ? AppColors.error : AppColors.success)),
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
