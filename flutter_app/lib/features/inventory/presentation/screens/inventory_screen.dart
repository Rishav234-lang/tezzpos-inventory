import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';



final inventoryStockProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryStock, queryParams: {'page': '1', 'limit': '500'});
  return response.data as Map<String, dynamic>;
});

final inventoryBatchesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryBatches, queryParams: {'page': '1', 'limit': '500', 'sortBy': 'expiryDate', 'sortOrder': 'asc'});
  return response.data as Map<String, dynamic>;
});

final inventoryAdjustmentsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryAdjustments, queryParams: {'page': '1', 'limit': '100'});
  return response.data as Map<String, dynamic>;
});

final lowStockProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryLowStock);
  return response.data as List<dynamic>;
});

final inventoryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryStats);
  return response.data as Map<String, dynamic>;
});



class InventoryScreen extends ConsumerStatefulWidget {

  const InventoryScreen({super.key});

  @override

  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();

}



class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;



  @override
  void initState() { super.initState(); _tabController = TabController(length: 4, vsync: this); }



  @override

  void dispose() { _tabController.dispose(); super.dispose(); }



  void _showAdjustmentDialog(Map<String, dynamic> item) {

    final qtyController = TextEditingController();

    String reason = 'MANUAL_ADJUSTMENT';

    showDialog(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text('Adjust Stock: ${item['name'] ?? ''}'),

        content: SizedBox(

          width: 350,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text('Current Stock: ${item['totalStock'] ?? 0}', style: TextStyle(color: Colors.grey.shade600)),

              const SizedBox(height: 16),

              TextField(

                controller: qtyController,

                decoration: const InputDecoration(labelText: 'Adjustment Qty (+ or -)', prefixIcon: Icon(Icons.inventory_2_outlined)),

                keyboardType: const TextInputType.numberWithOptions(signed: true),

              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(

                value: reason,

                decoration: const InputDecoration(labelText: 'Reason'),

                items: ['MANUAL_ADJUSTMENT', 'DAMAGED', 'EXPIRED', 'RETURNED', 'OTHER']

                    .map((r) => DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' ')))).toList(),

                onChanged: (v) => reason = v!,

              ),

            ],

          ),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),

          FilledButton(

            onPressed: () async {

              final qty = int.tryParse(qtyController.text);

              if (qty == null || qty == 0) return;

              final adjustmentType = qty > 0 ? 'INCREASE' : 'DECREASE';

              try {

                await ref.read(apiClientProvider).post(ApiConstants.inventoryAdjust, data: {

                  'productId': item['id'],

                  'adjustmentType': adjustmentType,

                  'quantity': qty.abs(),

                  'reason': reason,

                });

                ref.invalidate(inventoryStockProvider);
                ref.invalidate(inventoryBatchesProvider);
                ref.invalidate(inventoryAdjustmentsProvider);
                ref.invalidate(inventoryStatsProvider);
                ref.invalidate(lowStockProvider);

                if (mounted) {

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock adjusted'), backgroundColor: AppColors.success));

                }

              } catch (e) {

                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));

              }

            },

            child: const Text('Adjust'),

          ),

        ],

      ),

    );

  }



  void _showProductBatches(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['name'] ?? 'Product Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('SKU', item['sku'] ?? '-'),
                _detailRow('Category', item['category'] ?? '-'),
                _detailRow('Unit', item['unit'] ?? '-'),
                _detailRow('Min Stock', '${item['minStockLevel'] ?? 0}'),
                _detailRow('Selling Price', '₹${item['sellingPrice'] ?? 0}'),
                _detailRow('Total Stock', '${item['totalStock'] ?? 0}'),
                _detailRow('Stock Value', '₹${(item['stockValue'] ?? 0).toStringAsFixed(2)}'),
                const Divider(height: 24),
                const Text('Stock Status', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (item['isLowStock'] == true) ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (item['isLowStock'] == true) ? 'LOW STOCK' : 'HEALTHY',
                    style: TextStyle(fontWeight: FontWeight.w600, color: (item['isLowStock'] == true) ? AppColors.error : AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(inventoryStockProvider);
              ref.invalidate(inventoryBatchesProvider);
              ref.invalidate(inventoryAdjustmentsProvider);
              ref.invalidate(inventoryStatsProvider);
              ref.invalidate(lowStockProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Stock'),
            Tab(icon: Icon(Icons.layers_outlined), text: 'Batches'),
            Tab(icon: Icon(Icons.warning_amber_outlined), text: 'Low'),
            Tab(icon: Icon(Icons.history_outlined), text: 'History'),
          ],
        ),

      ),

      body: Column(
        children: [
          // Stats Header
          _InventoryStatsHeader(tabController: _tabController),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _CurrentStockTab(onAdjust: _showAdjustmentDialog, onViewBatches: _showProductBatches),
              const _BatchesTab(),
              const _LowStockTab(),
              const _HistoryTab(),
            ]),
          ),
        ],
      ),

    );

  }

}



// ─── Stats Header ─────────────────────────────────────────────────
class _InventoryStatsHeader extends ConsumerWidget {
  final TabController tabController;
  const _InventoryStatsHeader({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(inventoryStatsProvider);
    return statsAsync.when(
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            children: [
              _statChip('Products', '${stats['totalProducts'] ?? 0}', AppColors.primary),
              const SizedBox(width: 8),
              _statChip('Stock Qty', '${stats['totalStockQuantity'] ?? 0}', AppColors.success),
              const SizedBox(width: 8),
              _statChip('Value', '₹${((stats['inventoryValue'] ?? 0) as num).toStringAsFixed(0)}', AppColors.secondary),
              const SizedBox(width: 8),
              if ((stats['lowStockCount'] ?? 0) > 0)
                GestureDetector(
                  onTap: () => tabController.animateTo(2),
                  child: _statChip('Low', '${stats['lowStockCount']}', AppColors.error),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ─── Current Stock Tab ────────────────────────────────────────────
class _CurrentStockTab extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic>) onAdjust;
  final void Function(Map<String, dynamic>) onViewBatches;
  const _CurrentStockTab({required this.onAdjust, required this.onViewBatches});

  @override
  ConsumerState<_CurrentStockTab> createState() => _CurrentStockTabState();
}

class _CurrentStockTabState extends ConsumerState<_CurrentStockTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(inventoryStockProvider);
    return stockAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(inventoryStockProvider)),
      data: (result) {
        final items = (result['data'] as List<dynamic>?) ?? [];
        final filtered = _search.isEmpty
            ? items
            : items.where((i) =>
                (i['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
                (i['sku'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
                (i['barcode'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()),
              ).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU, barcode...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const AppEmptyState(message: 'No matching products', icon: Icons.search_off)
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(inventoryStockProvider);
                        await ref.read(inventoryStockProvider.future);
                      },
                      child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final stock = item['totalStock'] ?? 0;
                        final minStock = item['minStockLevel'] ?? 0;
                        final isLow = item['isLowStock'] == true || (stock <= minStock && minStock > 0);
                        final stockValue = (item['stockValue'] ?? 0) is num ? (item['stockValue'] as num).toDouble() : double.tryParse(item['stockValue']?.toString() ?? '0') ?? 0;

                        return Card(
                          color: isLow ? Colors.orange.shade50 : null,
                          child: InkWell(
                            onTap: () => widget.onViewBatches(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isLow ? AppColors.warning.withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
                                        child: Icon(Icons.inventory_2_outlined, size: 18, color: isLow ? AppColors.warning : AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            Text('${item['sku'] ?? ''} • ${item['unit'] ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isLow ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text('$stock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isLow ? AppColors.error : AppColors.success)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Min: $minStock', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _smallChip('Stock Value', '₹${stockValue.toStringAsFixed(0)}', AppColors.secondary),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _smallChip('Selling Price', '₹${item['sellingPrice'] ?? 0}', AppColors.primary),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.tune, size: 18),
                                        tooltip: 'Adjust Stock',
                                        onPressed: () => widget.onAdjust(item),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _smallChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─── Batches Tab ────────────────────────────────────────────────────
class _BatchesTab extends ConsumerStatefulWidget {
  const _BatchesTab({super.key});

  @override
  ConsumerState<_BatchesTab> createState() => _BatchesTabState();
}

class _BatchesTabState extends ConsumerState<_BatchesTab> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(inventoryBatchesProvider);
    return batchesAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(inventoryBatchesProvider)),
      data: (result) {
        final items = (result['data'] as List<dynamic>?) ?? [];
        // Local search filter
        final filtered = _search.isEmpty ? items : items.where((b) {
          final name = (b['product']?['name'] ?? '').toString().toLowerCase();
          final batchNum = (b['batchNumber'] ?? '').toString().toLowerCase();
          final sku = (b['product']?['sku'] ?? '').toString().toLowerCase();
          return name.contains(_search) || batchNum.contains(_search) || sku.contains(_search);
        }).toList();

        if (items.isEmpty) return const AppEmptyState(message: 'No batch data', icon: Icons.layers_outlined);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inventoryBatchesProvider);
            await ref.read(inventoryBatchesProvider.future);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by product, batch, SKU...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _search = ''); })
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              if (filtered.isEmpty)
                const Expanded(child: AppEmptyState(message: 'No matching batches', icon: Icons.search_off))
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      final expiry = (b['expiryDate'] ?? '').toString();
                      final expiryStr = expiry.length >= 10 ? expiry.substring(0, 10) : 'N/A';
                      final expiryDate = DateTime.tryParse(expiry);
                      final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
                      final daysRemaining = expiryDate != null ? expiryDate.difference(DateTime.now()).inDays : null;
                      final daysText = daysRemaining == null
                          ? ''
                          : daysRemaining < 0
                              ? 'Expired ${daysRemaining.abs()}d ago'
                              : daysRemaining == 0
                                  ? 'Expires today'
                                  : '${daysRemaining}d left';

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(b['product']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: b['status'] == 'ACTIVE' ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(b['status'] ?? 'UNKNOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: b['status'] == 'ACTIVE' ? AppColors.success : Colors.grey)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _batchChip('Batch', b['batchNumber'] ?? '-'),
                                  _batchChip('Qty', '${b['availableQuantity'] ?? 0}'),
                                  _batchChip('Buy', '₹${b['purchasePrice'] ?? 0}'),
                                  _batchChip('MRP', '₹${b['mrp'] ?? 0}'),
                                  if (daysText.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isExpired ? AppColors.error.withOpacity(0.08) : (daysRemaining != null && daysRemaining <= 30 ? AppColors.warning.withOpacity(0.08) : Colors.grey.shade100),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        daysText,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isExpired ? AppColors.error : (daysRemaining != null && daysRemaining <= 30 ? AppColors.warning : Colors.grey.shade700)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Vendor: ${b['vendor']?['name'] ?? '-'}  •  Purchase: ${_fmtDate(b['purchaseDate'])}  •  Expiry: $expiryStr',
                                style: TextStyle(fontSize: 11, color: isExpired ? AppColors.error : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _batchChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text('$label: $value', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
    );
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try { return DateFormat('dd MMM yy').format(DateTime.parse(d)); } catch (_) { return d.substring(0, 10); }
  }
}

// ─── Low Stock Tab ────────────────────────────────────────────────
class _LowStockTab extends ConsumerWidget {
  const _LowStockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockProvider);
    return lowStockAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(lowStockProvider)),
      data: (items) {
        if (items.isEmpty) return const AppEmptyState(message: 'All stock levels healthy!', icon: Icons.check_circle_outline);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(lowStockProvider);
            await ref.read(lowStockProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
            final item = items[index];
            final stock = item['totalStock'] ?? item['stock'] ?? 0;
            final minStock = item['minStockLevel'] ?? 0;
            return Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.error.withOpacity(0.15), child: const Icon(Icons.warning_amber, size: 20, color: AppColors.error)),
                title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('SKU: ${item['sku'] ?? '-'} • Min: $minStock', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text('$stock', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
                ),
              ),
            );
          },
        ),
      );
      },
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(inventoryAdjustmentsProvider);
    return historyAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(inventoryAdjustmentsProvider)),
      data: (result) {
        final items = (result['data'] as List<dynamic>?) ?? [];
        if (items.isEmpty) return const AppEmptyState(
          message: 'No stock adjustments yet.\nUse the Stock tab to adjust inventory.',
          icon: Icons.history_outlined,
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inventoryAdjustmentsProvider);
            await ref.read(inventoryAdjustmentsProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
            final h = items[index];
            final isIncrease = (h['adjustmentType'] ?? '').toString().toUpperCase() == 'INCREASE';
            final date = (h['createdAt'] ?? '').toString();
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncrease ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  child: Icon(isIncrease ? Icons.arrow_upward : Icons.arrow_downward, size: 18, color: isIncrease ? AppColors.success : AppColors.error),
                ),
                title: Text(h['product']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${h['reason']?.toString().replaceAll('_', ' ') ?? '-'} • ${_fmtDate(date)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Text('${isIncrease ? '+' : '-'}${h['quantity'] ?? 0}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isIncrease ? AppColors.success : AppColors.error)),
              ),
            );
          },
        ),
      );
      },
    );
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try { return DateFormat('dd MMM, hh:mm a').format(DateTime.parse(d).toLocal()); } catch (_) { return d.substring(0, 10); }
  }
}

