import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class SaleFormScreen extends ConsumerStatefulWidget {
  const SaleFormScreen({super.key});
  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  String? _selectedCustomerId;
  String _paymentMode = 'CASH';
  final _paidAmountController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final List<_SaleItem> _items = [];
  bool _isLoading = false;
  List<dynamic> _customers = [];
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = ref.read(apiClientProvider);
    try {
      final results = await Future.wait([
        api.get(ApiConstants.customers, queryParams: {'limit': '500'}),
        api.get(ApiConstants.products, queryParams: {'limit': '500', 'status': 'ACTIVE'}),
      ]);
      setState(() {
        _customers = results[0].data['data'] as List<dynamic>;
        _products = results[1].data['data'] as List<dynamic>;
      });
    } catch (_) {}
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _totalAmount => _subtotal - _discount;

  void _addItem() {
    showDialog(context: context, builder: (ctx) => _AddSaleItemDialog(
      products: _products,
      onAdd: (item) => setState(() => _items.add(item)),
    ));
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  Future<void> _handleSubmit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final paidAmount = double.tryParse(_paidAmountController.text) ?? _totalAmount;
      await api.post(ApiConstants.sales, data: {
        'customerId': _selectedCustomerId,
        'paymentMode': _paymentMode,
        'discount': _discount,
        'paidAmount': paidAmount,
        'items': _items.map((i) => i.toJson()).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully!'), backgroundColor: AppColors.success),
        );
        context.go('/sales');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('DioException') ? 'Failed to create sale. Check stock availability.' : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/sales')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer & Payment
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sale Details', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCustomerId,
                              decoration: const InputDecoration(labelText: 'Customer (optional)', prefixIcon: Icon(Icons.person_outlined)),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('Walk-in Customer')),
                                ..._customers.map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['name'] ?? ''))),
                              ],
                              onChanged: (v) => setState(() => _selectedCustomerId = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentMode,
                              decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.payment_outlined)),
                              items: ['CASH', 'UPI', 'CARD', 'CREDIT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setState(() => _paymentMode = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Items (${_items.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      if (_items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                              Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
                              Expanded(child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                              Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                              SizedBox(width: 40),
                            ],
                          ),
                        ),
                        ..._items.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(item.productName, style: const TextStyle(fontSize: 13))),
                                Expanded(child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                                Expanded(child: Text('₹${item.sellingPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                Expanded(child: Text('₹${item.total.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                SizedBox(width: 40, child: IconButton(icon: Icon(Icons.close, size: 16, color: Colors.red.shade400), onPressed: () => _removeItem(i))),
                              ],
                            ),
                          );
                        }),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('No items added yet. Click "Add Item" to start billing.', style: TextStyle(color: Colors.grey))),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Subtotal'), Text('₹${_subtotal.toStringAsFixed(2)}'),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: Text('Discount')),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _discountController,
                              decoration: const InputDecoration(prefixText: '₹ ', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Total Amount', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('₹${_totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ]),
                      if (_paymentMode == 'CREDIT') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _paidAmountController,
                          decoration: const InputDecoration(labelText: 'Amount Paid Now', prefixIcon: Icon(Icons.currency_rupee), isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Complete Sale', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sale Item Model ────────────────────────────────────────────────
class _SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double sellingPrice;

  _SaleItem({required this.productId, required this.productName, required this.quantity, required this.sellingPrice});

  double get total => quantity * sellingPrice;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'sellingPrice': sellingPrice,
  };
}

// ─── Add Sale Item Dialog ───────────────────────────────────────────
class _AddSaleItemDialog extends StatefulWidget {
  final List<dynamic> products;
  final Function(_SaleItem) onAdd;
  const _AddSaleItemDialog({required this.products, required this.onAdd});
  @override
  State<_AddSaleItemDialog> createState() => _AddSaleItemDialogState();
}

class _AddSaleItemDialogState extends State<_AddSaleItemDialog> {
  String? _selectedProductId;
  String _selectedProductName = '';
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  String _search = '';

  List<dynamic> get _filtered => _search.isEmpty
      ? widget.products
      : widget.products.where((p) =>
          (p['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
          (p['sku'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
          (p['barcode'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())
        ).toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sale Item'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Search product by name/SKU/barcode...', prefixIcon: Icon(Icons.search, size: 20), isDense: true),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final p = _filtered[i];
                    final isSelected = _selectedProductId == p['id'];
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      title: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13)),
                      subtitle: Text('MRP: ₹${p['sellingPrice'] ?? 0}', style: const TextStyle(fontSize: 11)),
                      onTap: () => setState(() {
                        _selectedProductId = p['id'];
                        _selectedProductName = p['name'] ?? '';
                        _priceController.text = '${p['sellingPrice'] ?? ''}';
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Quantity *', isDense: true), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Selling Price *', isDense: true), keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_selectedProductId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product'))); return; }
            final qty = int.tryParse(_qtyController.text);
            final price = double.tryParse(_priceController.text);
            if (qty == null || qty <= 0 || price == null || price <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid quantity and price')));
              return;
            }
            widget.onAdd(_SaleItem(productId: _selectedProductId!, productName: _selectedProductName, quantity: qty, sellingPrice: price));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
