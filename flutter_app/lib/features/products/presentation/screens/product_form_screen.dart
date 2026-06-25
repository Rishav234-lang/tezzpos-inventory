import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});
  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _minStockController = TextEditingController(text: '10');
  String _unit = 'PCS';
  String _status = 'ACTIVE';
  bool _isLoading = false;
  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadProduct();
  }

  Future<void> _loadProduct() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.products}/${widget.productId}');
    final p = response.data;
    _nameController.text = p['name'] ?? '';
    _skuController.text = p['sku'] ?? '';
    _barcodeController.text = p['barcode'] ?? '';
    _priceController.text = '${p['sellingPrice'] ?? ''}';
    _minStockController.text = '${p['minStockLevel'] ?? 10}';
    setState(() { _unit = p['unit'] ?? 'PCS'; _status = p['status'] ?? 'ACTIVE'; });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        'sellingPrice': double.parse(_priceController.text.trim()),
        'minStockLevel': int.parse(_minStockController.text.trim()),
        'unit': _unit,
        'status': _status,
      };
      if (_isEditing) {
        await api.put('${ApiConstants.products}/${widget.productId}', data: data);
      } else {
        await api.post(ApiConstants.products, data: data);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product ${_isEditing ? 'updated' : 'created'}'))); context.go('/products'); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextFormField(controller: _skuController, decoration: const InputDecoration(labelText: 'SKU'))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _barcodeController, decoration: const InputDecoration(labelText: 'Barcode'))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Selling Price (MRP) *'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _minStockController, decoration: const InputDecoration(labelText: 'Min Stock Level'), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(value: _unit, decoration: const InputDecoration(labelText: 'Unit'), items: ['PCS', 'KG', 'LTR', 'MTR', 'BOX', 'PACK'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setState(() => _unit = v!)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isLoading ? null : _handleSubmit, child: _isLoading ? const CircularProgressIndicator(strokeWidth: 2) : Text(_isEditing ? 'Update Product' : 'Create Product')),
            ]),
          ),
        ),
      ),
    );
  }
}
