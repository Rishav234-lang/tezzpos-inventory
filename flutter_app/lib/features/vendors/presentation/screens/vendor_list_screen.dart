import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

final vendorListProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.vendors, queryParams: params);
  return response.data as Map<String, dynamic>;
});

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});
  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
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

  Future<void> _deleteVendor(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).delete('${ApiConstants.vendors}/$id');
      ref.invalidate(vendorListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/vendors/add'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Vendor'),
          ),
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
                hintText: 'Search by name, mobile, or GST...',
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
            child: vendorsAsync.when(
              loading: () => const AppLoading(),
              error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(vendorListProvider)),
              data: (result) {
                final vendors = result['data'] as List<dynamic>;
                final pagination = result['pagination'] as Map<String, dynamic>?;
                if (vendors.isEmpty) {
                  return AppEmptyState(
                    message: _searchQuery.isNotEmpty ? 'No vendors match "$_searchQuery"' : 'No vendors yet',
                    icon: Icons.people_outlined,
                    actionLabel: 'Add Vendor',
                    onAction: () => context.go('/vendors/add'),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: vendors.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final v = vendors[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                (v['name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                            title: Text(v['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              [v['mobile'], v['gstNumber']].where((e) => e != null && e.toString().isNotEmpty).join(' | '),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (v['balance'] != null && v['balance'] != 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      label: Text('₹${v['balance']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                                      backgroundColor: AppColors.error.withOpacity(0.08),
                                      side: BorderSide.none,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Edit', onPressed: () => context.go('/vendors/${v['id']}/edit')),
                                IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), tooltip: 'Delete', onPressed: () => _deleteVendor(v['id'], v['name'])),
                              ],
                            ),
                            onTap: () => context.go('/vendors/${v['id']}/edit'),
                          );
                        },
                      ),
                    ),
                    if (pagination != null && (pagination['totalPages'] ?? 1) > 1)
                      _PaginationBar(
                        page: _page,
                        totalPages: pagination['totalPages'] ?? 1,
                        total: pagination['total'] ?? 0,
                        onPageChanged: (p) => setState(() => _page = p),
                      ),
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
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          Text('Page $page of $totalPages', style: const TextStyle(fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
