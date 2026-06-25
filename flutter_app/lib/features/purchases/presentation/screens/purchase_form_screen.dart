import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key});
  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0');
  String? _selectedVendorId;
  DateTime _purchaseDate = DateTime.now();
  final List<_PurchaseItem> _items = [];
  bool _isLoading = false;
  List<dynamic> _vendors = [];
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
        api.get(ApiConstants.vendors, queryParams: {'limit': '500'}),
        api.get(ApiConstants.products, queryParams: {'limit': '500'}),
      ]);
      setState(() {
        _vendors = results[0].data['data'] as List<dynamic>;
        _products = results[1].data['data'] as List<dynamic>;
      });
    } catch (_) {}
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.total);

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context, initialDate: _purchaseDate,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _purchaseDate = date);
  }

  void _addItem() {
    showDialog(context: context, builder: (ctx) => _AddItemDialog(
      products: _products,
      onAdd: (item) => setState(() => _items.add(item)),
    ));
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vendor')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.purchases, data: {
        'vendorId': _selectedVendorId,
        'invoiceNumber': _invoiceController.text.trim(),
        'purchaseDate': _purchaseDate.toUtc().toIso8601String(),
        'paidAmount': double.tryParse(_paidAmountController.text) ?? 0,
        'items': _items.map((i) => i.toJson()).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase created successfully'), backgroundColor: AppColors.success),
        );
        context.go('/purchases');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('DioException') ? 'Failed to create purchase. Check your data.' : 'Error: $e';
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
        title: const Text('New Purchase'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/purchases')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purchase Details', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _invoiceController,
                                decoration: const InputDecoration(labelText: 'Invoice Number *', prefixIcon: Icon(Icons.receipt_outlined)),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Invoice number is required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Purchase Date', prefixIcon: Icon(Icons.calendar_today_outlined)),
                                  child: Text(DateFormat('dd MMM yyyy').format(_purchaseDate)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedVendorId,
                          decoration: const InputDecoration(labelText: 'Select Vendor *', prefixIcon: Icon(Icons.people_outlined)),
                          items: _vendors.map((v) => DropdownMenuItem<String>(
                            value: v['id'] as String,
                            child: Text(v['name'] ?? ''),
                          )).toList(),
                          onChanged: (v) => setState(() {
                            _selectedVendorId = v;
                          }),
                          validator: (v) => v == null ? 'Please select a vendor' : null,
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
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                                const Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
                                const Expanded(child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                                const Expanded(child: Text('MRP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                                const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                                const SizedBox(width: 40),
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
                                  Expanded(child: Text('₹${item.purchasePrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                  Expanded(child: Text('₹${item.mrp.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                  Expanded(child: Text('₹${item.total.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  SizedBox(width: 40, child: IconButton(icon: Icon(Icons.close, size: 16, color: Colors.red.shade400), onPressed: () => _removeItem(i))),
                                ],
                              ),
                            );
                          }),
                        ] else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: Text('No items added yet. Click "Add Item" to begin.', style: TextStyle(color: Colors.grey))),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 16)),
                            Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _paidAmountController,
                          decoration: const InputDecoration(labelText: 'Paid Amount', prefixIcon: Icon(Icons.currency_rupee)),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Balance', style: TextStyle(color: Colors.grey)),
                            Text(
                              '₹${(_totalAmount - (double.tryParse(_paidAmountController.text) ?? 0)).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
                            ),
                          ],
                        ),
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
                        : const Text('Create Purchase', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Purchase Item Model ────────────────────────────────────────────
class _PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final double purchasePrice;
  final double mrp;
  final String? expiryDate;

  _PurchaseItem({required this.productId, required this.productName, required this.quantity, required this.purchasePrice, required this.mrp, this.expiryDate});

  double get total => quantity * purchasePrice;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'purchasePrice': purchasePrice,
    'mrp': mrp,
    if (expiryDate != null) 'expiryDate': expiryDate,
  };
}

// ─── Add Item Dialog ────────────────────────────────────────────────
class _AddItemDialog extends StatefulWidget {
  final List<dynamic> products;
  final Function(_PurchaseItem) onAdd;
  const _AddItemDialog({required this.products, required this.onAdd});
  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  String? _selectedProductId;
  String _selectedProductName = '';
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  DateTime? _expiryDate;
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
      title: const Text('Add Purchase Item'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product search
              TextField(
                decoration: const InputDecoration(hintText: 'Search product by name/SKU/barcode...', prefixIcon: Icon(Icons.search, size: 20), isDense: true),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
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
                      subtitle: Text('SKU: ${p['sku'] ?? 'N/A'} | MRP: ₹${p['sellingPrice'] ?? 0}', style: const TextStyle(fontSize: 11)),
                      onTap: () => setState(() {
                        _selectedProductId = p['id'];
                        _selectedProductName = p['name'] ?? '';
                        _mrpController.text = '${p['sellingPrice'] ?? ''}';
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
                  Expanded(child: TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Purchase Price *', isDense: true), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _mrpController, decoration: const InputDecoration(labelText: 'MRP *', isDense: true), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2040));
                        if (date != null) setState(() => _expiryDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Expiry Date', isDense: true),
                        child: Text(_expiryDate != null ? DateFormat('dd/MM/yyyy').format(_expiryDate!) : 'Select', style: TextStyle(fontSize: 13, color: _expiryDate != null ? Colors.black : Colors.grey)),
                      ),
                    ),
                  ),
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
            final mrp = double.tryParse(_mrpController.text);
            if (qty == null || qty <= 0 || price == null || price <= 0 || mrp == null || mrp <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid quantity, price, and MRP')));
              return;
            }
            widget.onAdd(_PurchaseItem(
              productId: _selectedProductId!,
              productName: _selectedProductName,
              quantity: qty,
              purchasePrice: price,
              mrp: mrp,
              expiryDate: _expiryDate?.toUtc().toIso8601String(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
