import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

final customerPaymentsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.paymentsCustomer, queryParams: {'page': '1', 'limit': '50'});
  return response.data as Map<String, dynamic>;
});

final vendorPaymentsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.paymentsVendor, queryParams: {'page': '1', 'limit': '50'});
  return response.data as Map<String, dynamic>;
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

  void _showAddPaymentDialog(bool isCustomer) {
    showDialog(context: context, builder: (ctx) => _AddPaymentDialog(
      isCustomer: isCustomer,
      onPaymentAdded: () {
        ref.invalidate(customerPaymentsProvider);
        ref.invalidate(vendorPaymentsProvider);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Customer Payments'),
          Tab(text: 'Vendor Payments'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _PaymentListTab(provider: customerPaymentsProvider, isCustomer: true, entityKey: 'customer'),
        _PaymentListTab(provider: vendorPaymentsProvider, isCustomer: false, entityKey: 'vendor'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentDialog(_tabController.index == 0),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
    );
  }
}

class _PaymentListTab extends ConsumerWidget {
  final AutoDisposeFutureProvider<Map<String, dynamic>> provider;
  final bool isCustomer;
  final String entityKey;
  const _PaymentListTab({required this.provider, required this.isCustomer, required this.entityKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(provider);

    return paymentsAsync.when(
      loading: () => const AppLoading(),
      error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(provider)),
      data: (result) {
        final payments = result['data'] as List<dynamic>;
        if (payments.isEmpty) {
          return AppEmptyState(
            message: isCustomer ? 'No customer payments yet' : 'No vendor payments yet',
            icon: Icons.payment_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = payments[index];
            final date = (p['paymentDate'] ?? '').toString();
            final dateStr = date.length >= 10 ? date.substring(0, 10) : '';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (isCustomer ? AppColors.success : AppColors.error).withOpacity(0.1),
                child: Icon(isCustomer ? Icons.arrow_downward : Icons.arrow_upward, size: 20, color: isCustomer ? AppColors.success : AppColors.error),
              ),
              title: Text(p[entityKey]?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('${p['paymentMode'] ?? ''} • $dateStr', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              trailing: Text(
                '₹${p['amount'] ?? 0}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isCustomer ? AppColors.success : AppColors.error),
              ),
            );
          },
        );
      },
    );
  }
}

class _AddPaymentDialog extends ConsumerStatefulWidget {
  final bool isCustomer;
  final VoidCallback onPaymentAdded;
  const _AddPaymentDialog({required this.isCustomer, required this.onPaymentAdded});
  @override
  ConsumerState<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<_AddPaymentDialog> {
  final _amountController = TextEditingController();
  String _paymentMode = 'CASH';
  String? _selectedEntityId;
  List<dynamic> _entities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    final api = ref.read(apiClientProvider);
    try {
      final endpoint = widget.isCustomer ? ApiConstants.customers : ApiConstants.vendors;
      final response = await api.get(endpoint, queryParams: {'limit': '500'});
      setState(() => _entities = response.data['data'] as List<dynamic>);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_selectedEntityId == null || _amountController.text.isEmpty) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final endpoint = widget.isCustomer ? ApiConstants.paymentsCustomer : ApiConstants.paymentsVendor;
      final idKey = widget.isCustomer ? 'customerId' : 'vendorId';
      await api.post(endpoint, data: {
        idKey: _selectedEntityId,
        'amount': amount,
        'paymentMode': _paymentMode,
        'paymentDate': DateTime.now().toIso8601String(),
      });
      widget.onPaymentAdded();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isCustomer ? 'Customer' : 'Vendor';
    return AlertDialog(
      title: Text('Record $label Payment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedEntityId,
              decoration: InputDecoration(labelText: 'Select $label *'),
              items: _entities.map((e) => DropdownMenuItem<String>(value: e['id'] as String, child: Text(e['name'] ?? ''))).toList(),
              onChanged: (v) => setState(() => _selectedEntityId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *', prefixIcon: Icon(Icons.currency_rupee)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment Mode'),
              items: ['CASH', 'UPI', 'CARD', 'BANK_TRANSFER', 'CHEQUE'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _paymentMode = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Record'),
        ),
      ],
    );
  }
}
