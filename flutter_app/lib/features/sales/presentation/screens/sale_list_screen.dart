import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';

import '../../../../core/constants/api_constants.dart';

import '../../../../core/widgets/app_loading.dart';

import '../../../../core/theme/app_theme.dart';



final saleListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {

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
  Map<String, String> _currentParams = {'page': '1', 'limit': '20'};

  void _updateParams() {
    _currentParams = {'page': '$_page', 'limit': '20'};
  }

  @override
  void initState() { super.initState(); _updateParams(); }

  Future<void> _showQuickPayment(BuildContext ctx, String id, double balance, double total, double paid) async {
    final controller = TextEditingController(text: balance.toStringAsFixed(2));
    final amount = await showDialog<double>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: const Icon(Icons.currency_rupee),
            helperText: 'Balance: ₹${balance.toStringAsFixed(2)}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) Navigator.pop(dialogCtx, val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (amount == null) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.patch('${ApiConstants.sales}/$id', data: {
        'paidAmount': paid + amount,
      });
      ref.invalidate(saleListProvider(_currentParams));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _showStatusUpdate(BuildContext ctx, String id, String current) async {
    final statuses = ['UNPAID', 'PARTIAL', 'PAID'];
    final selected = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('Update Status'),
        children: statuses.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogCtx, s),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: s == 'PAID' ? AppColors.success : s == 'PARTIAL' ? Colors.orange : AppColors.error),
              const SizedBox(width: 12),
              Text(s),
              if (s == current) ...[const SizedBox(width: 8), const Icon(Icons.check, size: 16, color: AppColors.success)],
            ],
          ),
        )).toList(),
      ),
    );
    if (selected == null || selected == current) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.patch('${ApiConstants.sales}/$id', data: {'status': selected});
      ref.invalidate(saleListProvider(_currentParams));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $selected'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {

    final salesAsync = ref.watch(saleListProvider(_currentParams));



    return Scaffold(

      appBar: AppBar(

        title: const Text('Sales'),

        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: () => ref.invalidate(saleListProvider(_currentParams))),
          FilledButton.icon(onPressed: () => context.push('/sales/add'), icon: const Icon(Icons.add, size: 18), label: const Text('New Sale')),
          const SizedBox(width: 16),
        ],

      ),

      body: salesAsync.when(

        loading: () => const AppLoading(),

        error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(saleListProvider(_currentParams))),

        data: (result) {

          final sales = result['data'] as List<dynamic>;

          final pagination = result['pagination'] as Map<String, dynamic>?;

          if (sales.isEmpty) {

            return AppEmptyState(

              message: 'No sales yet',

              icon: Icons.point_of_sale_outlined,

              actionLabel: 'New Sale',

              onAction: () => context.push('/sales/add'),

            );

          }

          return Column(

            children: [

              Expanded(

                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(saleListProvider(_currentParams));
                    await ref.read(saleListProvider(_currentParams).future);
                  },
                  child: ListView.separated(

                  padding: const EdgeInsets.all(16),

                  itemCount: sales.length,

                  separatorBuilder: (_, __) => const Divider(height: 1),

                  itemBuilder: (context, index) {

                    final s = sales[index];
                    final status = s['status'] ?? s['paymentStatus'] ?? 'UNPAID';
                    final date = (s['invoiceDate'] ?? s['saleDate'] ?? s['createdAt'] ?? '').toString();
                    final dateStr = date.length >= 10 ? date.substring(0, 10) : '';
                    final totalAmt = s['totalAmount'] is num ? (s['totalAmount'] as num).toDouble() : double.tryParse(s['totalAmount']?.toString() ?? '0') ?? 0;
                    final paidAmt = s['paidAmount'] is num ? (s['paidAmount'] as num).toDouble() : double.tryParse(s['paidAmount']?.toString() ?? '0') ?? 0;
                    final balance = totalAmt - paidAmt;

                    return ListTile(
                      onTap: () => context.push('/sales/${s['id']}'),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.point_of_sale_outlined, size: 20, color: AppColors.primary),
                      ),
                      title: Text(s['invoiceNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s['customer']?['name'] ?? 'Walk-in'} • $dateStr • ${s['paymentMode'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${totalAmt.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'view') context.push('/sales/${s['id']}');
                              if (value == 'pay' && balance > 0) _showQuickPayment(context, s['id'], balance, totalAmt, paidAmt);
                              if (value == 'status') _showStatusUpdate(context, s['id'], status);
                              if (value == 'invoice') context.push('/sales/${s['id']}');
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View Details')])),
                              if (balance > 0) const PopupMenuItem(value: 'pay', child: Row(children: [Icon(Icons.payment, size: 18), SizedBox(width: 8), Text('Record Payment')])),
                              const PopupMenuItem(value: 'status', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Update Status')])),
                              const PopupMenuItem(value: 'invoice', child: Row(children: [Icon(Icons.receipt_long, size: 18), SizedBox(width: 8), Text('View Invoice')])),
                            ],
                          ),
                        ],
                      ),
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

    );

  }

}

