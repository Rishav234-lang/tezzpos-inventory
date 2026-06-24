import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

final saleListProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.sales, queryParams: params);
  return response.data as Map<String, dynamic>;
});

class SaleListScreen extends ConsumerStatefulWidget {
  const SaleListScreen({super.key});
  @override
  ConsumerState<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends ConsumerState<SaleListScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(saleListProvider({'page': '$_page', 'limit': '20'}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          FilledButton.icon(onPressed: () => context.go('/sales/add'), icon: const Icon(Icons.add, size: 18), label: const Text('New Sale')),
          const SizedBox(width: 16),
        ],
      ),
      body: salesAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(saleListProvider)),
        data: (result) {
          final sales = result['data'] as List<dynamic>;
          final pagination = result['pagination'] as Map<String, dynamic>?;
          if (sales.isEmpty) {
            return AppEmptyState(
              message: 'No sales yet',
              icon: Icons.point_of_sale_outlined,
              actionLabel: 'New Sale',
              onAction: () => context.go('/sales/add'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = sales[index];
                    final status = s['paymentStatus'] ?? '';
                    final date = (s['saleDate'] ?? '').toString();
                    final dateStr = date.length >= 10 ? date.substring(0, 10) : '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.point_of_sale_outlined, size: 20, color: AppColors.primary),
                      ),
                      title: Text(s['invoiceNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s['customer']?['name'] ?? 'Walk-in'} • $dateStr • ${s['paymentMode'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${s['totalAmount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'PAID' ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status == 'PAID' ? AppColors.success : AppColors.warning)),
                          ),
                        ],
                      ),
                    );
                  },
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
                      IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _page > 1 ? () => setState(() => _page--) : null),
                      Text('Page $_page of ${pagination['totalPages']}', style: const TextStyle(fontSize: 13)),
                      IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _page < (pagination['totalPages'] ?? 1) ? () => setState(() => _page++) : null),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
