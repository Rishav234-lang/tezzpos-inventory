import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';

import '../../../../core/constants/api_constants.dart';

import '../../../../core/widgets/app_loading.dart';

import '../../../../core/theme/app_theme.dart';



final customerListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {

  final api = ref.read(apiClientProvider);

  final response = await api.get(ApiConstants.customers, queryParams: params);

  return response.data as Map<String, dynamic>;

});



class CustomerListScreen extends ConsumerStatefulWidget {

  const CustomerListScreen({super.key});

  @override

  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();

}



class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {

  final _searchController = TextEditingController();

  String _searchQuery = '';

  int _page = 1;

  Timer? _debounce;



  @override
  void initState() { super.initState(); _updateParams(); }

  @override
  void dispose() { _debounce?.cancel(); _searchController.dispose(); super.dispose(); }



  void _onSearchChanged(String value) {

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {

      setState(() { _searchQuery = value; _page = 1; _updateParams(); });

    });

  }



  Map<String, String> _currentParams = {'page': '1', 'limit': '20'};

  void _updateParams() {
    _currentParams = {'page': '$_page', 'limit': '20', if (_searchQuery.isNotEmpty) 'search': _searchQuery};
  }

  Future<void> _deleteCustomer(String id, String name) async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: const Text('Delete Customer'),

        content: Text('Are you sure you want to delete "$name"?'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),

          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),

        ],

      ),

    );

    if (confirmed != true) return;

    try {

      await ref.read(apiClientProvider).delete('${ApiConstants.customers}/$id');

      ref.invalidate(customerListProvider(_currentParams));

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));

    } catch (e) {

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));

    }

  }



  @override

  Widget build(BuildContext context) {

    final customersAsync = ref.watch(customerListProvider(_currentParams));



    return Scaffold(

      appBar: AppBar(

        title: const Text('Customers'),

        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: () => ref.invalidate(customerListProvider(_currentParams))),
          FilledButton.icon(onPressed: () => context.push('/customers/add'), icon: const Icon(Icons.add, size: 18), label: const Text('Add Customer')),
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

                hintText: 'Search by name or mobile...',

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

            child: customersAsync.when(

              loading: () => const AppLoading(),

              error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(customerListProvider(_currentParams))),

              data: (result) {

                final customers = result['data'] as List<dynamic>;

                final pagination = result['pagination'] as Map<String, dynamic>?;

                if (customers.isEmpty) {

                  return AppEmptyState(

                    message: _searchQuery.isNotEmpty ? 'No customers match "$_searchQuery"' : 'No customers yet',

                    icon: Icons.person_outlined,

                    actionLabel: 'Add Customer',

                    onAction: () => context.push('/customers/add'),

                  );

                }

                return Column(

                  children: [

                    Expanded(

                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(customerListProvider(_currentParams));
                          await ref.read(customerListProvider(_currentParams).future);
                        },
                        child: ListView.separated(

                        padding: const EdgeInsets.symmetric(horizontal: 16),

                        itemCount: customers.length,

                        separatorBuilder: (_, __) => const Divider(height: 1),

                        itemBuilder: (context, index) {

                          final c = customers[index];

                          final balance = (c['balance'] ?? 0).toDouble();

                          return ListTile(

                            leading: CircleAvatar(

                              backgroundColor: AppColors.primary.withOpacity(0.1),

                              child: Text((c['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),

                            ),

                            title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),

                            subtitle: Text(c['mobile'] ?? 'No phone', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

                            trailing: Row(

                              mainAxisSize: MainAxisSize.min,

                              children: [

                                if (balance != 0)

                                  Container(

                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                                    decoration: BoxDecoration(

                                      color: balance > 0 ? AppColors.error.withOpacity(0.08) : AppColors.success.withOpacity(0.08),

                                      borderRadius: BorderRadius.circular(12),

                                    ),

                                    child: Text(

                                      '₹${balance.abs().toStringAsFixed(0)}',

                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: balance > 0 ? AppColors.error : AppColors.success),

                                    ),

                                  ),

                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Edit', onPressed: () => context.push('/customers/${c['id']}/edit')),

                                IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), tooltip: 'Delete', onPressed: () => _deleteCustomer(c['id'], c['name'])),

                              ],

                            ),

                            onTap: () => context.push('/customers/${c['id']}'),

                          );

                        },

                      ),

                      ),

                    ),

                    if (pagination != null && (pagination['totalPages'] ?? 1) > 1)

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),

                        child: Row(

                          children: [

                            Text('${pagination['total'] ?? 0} total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

                            const Spacer(),

                            IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _page > 1 ? () => setState(() { _page--; _updateParams(); }) : null),

                            Text('Page $_page of ${pagination['totalPages']}', style: const TextStyle(fontSize: 13)),

                            IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _page < (pagination['totalPages'] ?? 1) ? () => setState(() { _page++; _updateParams(); }) : null),

                          ],

                        ),

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

