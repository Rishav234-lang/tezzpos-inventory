import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

final productListProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.products, queryParams: params);
  return response.data as Map<String, dynamic>;
});

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});
  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _page = 1;
  Timer? _debounce;

  @override
  void dispose() { _debounce?.cancel(); _searchController.dispose(); super.dispose(); }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() { _searchQuery = value; _page = 1; });
    });
  }

  Map<String, String> get _params {
    final p = <String, String>{'page': '$_page', 'limit': '20'};
    if (_searchQuery.isNotEmpty) p['search'] = _searchQuery;
    return p;
  }

  Future<void> _deleteProduct(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).delete('${ApiConstants.products}/$id');
      ref.invalidate(productListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          FilledButton.icon(onPressed: () => context.go('/products/add'), icon: const Icon(Icons.add, size: 18), label: const Text('Add Product')),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, or barcode...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); _onSearchChanged(''); })
                    : null,
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const AppLoading(),
              error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(productListProvider)),
              data: (result) {
                final products = result['data'] as List<dynamic>;
                final pagination = result['pagination'] as Map<String, dynamic>?;
                if (products.isEmpty) {
                  return AppEmptyState(
                    message: _searchQuery.isNotEmpty ? 'No products match "$_searchQuery"' : 'No products yet',
                    icon: Icons.shopping_bag_outlined,
                    actionLabel: 'Add Product',
                    onAction: () => context.go('/products/add'),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = products[index];
                          final status = p['status'] ?? 'ACTIVE';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.secondary.withOpacity(0.1),
                              child: Text((p['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary)),
                            ),
                            title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text('SKU: ${p['sku'] ?? 'N/A'} | Unit: ${p['unit'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₹${p['sellingPrice'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: status == 'ACTIVE' ? AppColors.success.withOpacity(0.1) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status == 'ACTIVE' ? AppColors.success : Colors.grey)),
                                ),
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Edit', onPressed: () => context.go('/products/${p['id']}/edit')),
                                IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), tooltip: 'Delete', onPressed: () => _deleteProduct(p['id'], p['name'])),
                              ],
                            ),
                            onTap: () => context.go('/products/${p['id']}/edit'),
                          );
                        },
                      ),
                    ),
                    if (pagination != null && (pagination['totalPages'] ?? 1) > 1)
                      _PaginationBar(page: _page, totalPages: pagination['totalPages'] ?? 1, total: pagination['total'] ?? 0, onPageChanged: (p) => setState(() => _page = p)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page, totalPages, total;
  final ValueChanged<int> onPageChanged;
  const _PaginationBar({required this.page, required this.totalPages, required this.total, required this.onPageChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Text('$total total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: page > 1 ? () => onPageChanged(page - 1) : null),
          Text('Page $page of $totalPages', style: const TextStyle(fontSize: 13)),
          IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: page < totalPages ? () => onPageChanged(page + 1) : null),
        ],
      ),
    );
  }
}
