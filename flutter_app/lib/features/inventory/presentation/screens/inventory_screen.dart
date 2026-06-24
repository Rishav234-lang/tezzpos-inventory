import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

final inventoryStockProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryStock, queryParams: {'page': '1', 'limit': '100'});
  return response.data as Map<String, dynamic>;
});

final lowStockProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryLowStock);
  return response.data as List<dynamic>;
});

final nearExpiryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryNearExpiry);
  return response.data as List<dynamic>;
});

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _showAdjustmentDialog(Map<String, dynamic> item) {
    final qtyController = TextEditingController();
    String reason = 'MANUAL_ADJUSTMENT';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust Stock: ${item['product']?['name'] ?? ''}'),
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
              if (qty == null) return;
              try {
                await ref.read(apiClientProvider).post(ApiConstants.inventoryAdjust, data: {
                  'productId': item['productId'] ?? item['product']?['id'],
                  'quantity': qty,
                  'reason': reason,
                });
                ref.invalidate(inventoryStockProvider);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Current Stock'),
          Tab(icon: Icon(Icons.warning_amber_outlined), text: 'Low Stock'),
          Tab(icon: Icon(Icons.schedule_outlined), text: 'Near Expiry'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _CurrentStockTab(onAdjust: _showAdjustmentDialog),
        const _LowStockTab(),
        const _NearExpiryTab(),
      ]),
    );
  }
}

class _CurrentStockTab extends ConsumerWidget {
  final void Function(Map<String, dynamic>) onAdjust;
  const _CurrentStockTab({required this.onAdjust});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(inventoryStockProvider);

    return stockAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(inventoryStockProvider)),
      data: (result) {
        final items = result['data'] as List<dynamic>;
        if (items.isEmpty) return const AppEmptyState(message: 'No inventory data', icon: Icons.inventory_2_outlined);
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = items[index];
            final stock = item['totalStock'] ?? 0;
            final minStock = item['product']?['minStockLevel'] ?? 0;
            final isLow = stock <= minStock && minStock > 0;
            return Card(
              color: isLow ? Colors.orange.shade50 : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLow ? AppColors.warning.withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.inventory_2_outlined, size: 20, color: isLow ? AppColors.warning : AppColors.primary),
                ),
                title: Text(item['product']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Unit: ${item['product']?['unit'] ?? ''} | Min: $minStock', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLow ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('$stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isLow ? AppColors.error : AppColors.success)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(icon: const Icon(Icons.tune, size: 18), tooltip: 'Adjust Stock', onPressed: () => onAdjust(item)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.warning.withOpacity(0.15), child: const Icon(Icons.warning_amber, size: 20, color: AppColors.warning)),
                title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Min Level: ${item['minStockLevel'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text('${item['stock'] ?? 0}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NearExpiryTab extends ConsumerWidget {
  const _NearExpiryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearExpiryAsync = ref.watch(nearExpiryProvider);

    return nearExpiryAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(nearExpiryProvider)),
      data: (items) {
        if (items.isEmpty) return const AppEmptyState(message: 'No near-expiry items', icon: Icons.check_circle_outline);
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = items[index];
            final expiry = (item['expiryDate'] ?? '').toString();
            final expiryStr = expiry.length >= 10 ? expiry.substring(0, 10) : 'N/A';
            return Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.error.withOpacity(0.15), child: const Icon(Icons.schedule, size: 20, color: AppColors.error)),
                title: Text(item['product']?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Batch: ${item['batchNumber'] ?? ''} • Expires: $expiryStr', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text('Qty: ${item['currentQuantity'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
