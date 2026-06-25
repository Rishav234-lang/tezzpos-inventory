import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

final outstandingCustomersProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.outstandingCustomers);
  return response.data as List<dynamic>;
});

final outstandingVendorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.outstandingVendors);
  return response.data as List<dynamic>;
});

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _showPayDialog({required String entityId, required String name, required double outstanding, required bool isCustomer}) async {
    final controller = TextEditingController(text: outstanding.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record Payment - $name'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: const Icon(Icons.currency_rupee),
            helperText: 'Outstanding: ₹${outstanding.toStringAsFixed(2)}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    if (result == null) return;

    setState(() {});
    try {
      final api = ref.read(apiClientProvider);
      final endpoint = isCustomer ? ApiConstants.sales : ApiConstants.purchases;
      // Fetch oldest unpaid invoice for this entity
      final listResponse = await api.get(endpoint, queryParams: {
        'limit': '10',
        if (isCustomer) 'customerId': entityId else 'vendorId': entityId,
      });
      final items = (listResponse.data['data'] as List<dynamic>?) ?? [];
      final unpaid = items.firstWhere(
        (item) => item['status'] != 'PAID',
        orElse: () => null,
      );
      if (unpaid == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No unpaid invoice found')));
        return;
      }

      final currentPaid = unpaid['paidAmount'] is num ? (unpaid['paidAmount'] as num).toDouble() : double.tryParse(unpaid['paidAmount']?.toString() ?? '0') ?? 0;
      await api.patch('$endpoint/${unpaid['id']}', data: {
        'paidAmount': currentPaid + result,
      });

      if (isCustomer) {
        ref.invalidate(outstandingCustomersProvider);
      } else {
        ref.invalidate(outstandingVendorsProvider);
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(outstandingCustomersProvider);
              ref.invalidate(outstandingVendorsProvider);
            },
          ),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Customer Payments'),
          Tab(text: 'Vendor Payments'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _OutstandingListTab(
          provider: outstandingCustomersProvider,
          isCustomer: true,
          onPay: (id, name, outstanding) => _showPayDialog(entityId: id, name: name, outstanding: outstanding, isCustomer: true),
          onNavigate: (id) => context.go('/customers/$id'),
        ),
        _OutstandingListTab(
          provider: outstandingVendorsProvider,
          isCustomer: false,
          onPay: (id, name, outstanding) => _showPayDialog(entityId: id, name: name, outstanding: outstanding, isCustomer: false),
          onNavigate: (id) => context.go('/vendors/$id'),
        ),
      ]),
    );
  }
}

class _OutstandingListTab extends ConsumerWidget {
  final FutureProvider<List<dynamic>> provider;
  final bool isCustomer;
  final void Function(String id, String name, double outstanding) onPay;
  final void Function(String id) onNavigate;

  const _OutstandingListTab({required this.provider, required this.isCustomer, required this.onPay, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return async.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(provider)),
      data: (items) {
        if (items.isEmpty) {
          return AppEmptyState(
            message: isCustomer ? 'No outstanding customers' : 'No outstanding vendors',
            icon: Icons.check_circle_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(provider);
            await ref.read(provider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = items[index];
              final total = item[isCustomer ? 'totalSales' : 'totalPurchases'] ?? 0;
              final paid = item['totalPaid'] ?? 0;
              final outstanding = item['outstanding'] ?? 0;
              final invoices = (item['unpaidInvoices'] as List<dynamic>?) ?? [];

              return Card(
                child: InkWell(
                  onTap: () => onNavigate(item['id']),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(isCustomer ? Icons.person : Icons.business, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text(item['mobile'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${_fmt(total)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('Total ${isCustomer ? 'Sales' : 'Purchases'}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _amtCard('Paid', _fmt(paid), AppColors.success)),
                            const SizedBox(width: 8),
                            Expanded(child: _amtCard('Due', _fmt(outstanding), AppColors.error)),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => onPay(item['id'], item['name'] ?? '', outstanding is num ? outstanding.toDouble() : double.tryParse(outstanding.toString()) ?? 0),
                              child: const Text('Pay', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        // Show unpaid invoices
                        if (invoices.isNotEmpty) ...[
                          const Divider(height: 14),
                          ...invoices.take(3).map((inv) {
                            final invBalance = (inv['totalAmount'] ?? 0) - (inv['paidAmount'] ?? 0);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text(inv['invoiceNumber'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                  const Spacer(),
                                  Text('₹${_fmt(inv['totalAmount'])}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const SizedBox(width: 4),
                                  Text('(Bal: ₹${_fmt(invBalance)})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                                ],
                              ),
                            );
                          }),
                          if (invoices.length > 3)
                            Text('+${invoices.length - 3} more invoices', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _amtCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  String _fmt(dynamic val) {
    if (val == null) return '0';
    if (val is num) return val.toStringAsFixed(0);
    final d = double.tryParse(val.toString()) ?? 0;
    return d.toStringAsFixed(0);
  }
}

