import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_providers.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _minStockController = TextEditingController(text: '10');
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String _unit = 'PCS';
  double _gstRate = 0;
  String _status = 'ACTIVE';
  bool _isSaving = false;
  bool _controllersSet = false;

  bool get isEdit => widget.productId != null;

  final List<String> _units = [
    'PCS',
    'KG',
    'LTR',
    'BOX',
    'PACK',
    'BOTTLE',
    'DOZEN',
  ];
  final List<double> _gstRates = [0, 5, 12, 18, 28];

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _setControllersFromProduct(Product product) {
    if (_controllersSet) return;
    _nameController.text = product.name;
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _buyPriceController.text = product.costPrice.toStringAsFixed(2);
    _sellPriceController.text = product.sellingPrice.toStringAsFixed(2);
    _minStockController.text = product.minStockLevel.toString();
    _descriptionController.text = product.description ?? '';
    _selectedCategoryId = product.categoryId;
    _unit = product.unit;
    _gstRate = product.gstRate;
    _status = product.status;
    _controllersSet = true;
  }

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      final productAsync = ref.watch(productDetailProvider(widget.productId!));
      productAsync.whenData((product) {
        if (mounted) _setControllersFromProduct(product);
      });
    }

    final categoriesAsync = ref.watch(categoriesProvider(''));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Create Product'),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildFormCard(
              children: [
                _buildField(
                  label: 'Product Name',
                  required: true,
                  child: TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Example: Parle-G Biscuit'),
                  ),
                ),
                _gap(),
                _buildField(
                  label: 'Category',
                  required: true,
                  child: _buildCategoryDropdown(categoriesAsync),
                ),
                _gap(),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Unit',
                        required: true,
                        child: _buildUnitDropdown(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Sell Price',
                        required: true,
                        child: TextField(
                          controller: _sellPriceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0.00'),
                        ),
                      ),
                    ),
                  ],
                ),
                _gap(),
                _buildField(
                  label: 'Minimum Stock',
                  child: TextField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Example: 10'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildMoreDetails(),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? 'Update Product' : 'Create Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simple product setup',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock and buy price will come from Purchase.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildMoreDetails() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.tune, color: AppColors.primary),
          title: const Text(
            'More details',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Optional code, barcode, tax and note'),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Product Code',
                    child: TextField(
                      controller: _skuController,
                      decoration: _inputDecoration('Auto if empty'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: 'Barcode',
                    child: TextField(
                      controller: _barcodeController,
                      decoration: _inputDecoration('Optional'),
                    ),
                  ),
                ),
              ],
            ),
            _gap(),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Buy Price',
                    child: TextField(
                      controller: _buyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('0.00'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(label: 'Tax', child: _buildGstDropdown()),
                ),
              ],
            ),
            _gap(),
            _buildField(
              label: 'Note',
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: _inputDecoration('Optional'),
              ),
            ),
            if (isEdit) ...[
              _gap(),
              _buildField(label: 'Status', child: _buildStatusToggle()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _gap() => const SizedBox(height: 18);

  Widget _buildCategoryDropdown(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) => _dropdownShell(
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCategoryId,
            isExpanded: true,
            hint: const Text('Select category'),
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Failed to load categories'),
    );
  }

  Widget _buildUnitDropdown() {
    return _dropdownShell(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unit,
          isExpanded: true,
          items: _units
              .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _unit = value);
          },
        ),
      ),
    );
  }

  Widget _buildGstDropdown() {
    return _dropdownShell(
      DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _gstRate,
          isExpanded: true,
          items: _gstRates
              .map(
                (rate) => DropdownMenuItem(
                  value: rate,
                  child: Text('${rate.toStringAsFixed(0)}%'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _gstRate = value);
          },
        ),
      ),
    );
  }

  Widget _dropdownShell(Widget child) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }

  Widget _buildStatusToggle() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Active'),
            selected: _status == 'ACTIVE',
            onSelected: (_) => setState(() => _status = 'ACTIVE'),
            selectedColor: AppColors.successLight,
            labelStyle: TextStyle(
              color: _status == 'ACTIVE'
                  ? AppColors.success
                  : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Inactive'),
            selected: _status == 'INACTIVE',
            onSelected: (_) => setState(() => _status = 'INACTIVE'),
            selectedColor: AppColors.errorLight,
            labelStyle: TextStyle(
              color: _status == 'INACTIVE'
                  ? AppColors.error
                  : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.16),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.16),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter product name');
      return;
    }
    if (_selectedCategoryId == null) {
      _showSnack('Please select category');
      return;
    }

    final sellPrice = double.tryParse(_sellPriceController.text.trim());
    if (sellPrice == null) {
      _showSnack('Please enter valid sell price');
      return;
    }

    var sku = _skuController.text.trim();
    if (sku.isEmpty) {
      final cleaned = name
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
        7,
      );
      sku = '${cleaned.isEmpty ? 'ITEM' : cleaned}-$suffix';
    }

    final buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0;
    final barcode = _barcodeController.text.trim();
    final description = _descriptionController.text.trim();
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 10;

    setState(() => _isSaving = true);

    final data = {
      'name': name,
      'sku': sku,
      'barcode': barcode.isNotEmpty ? barcode : null,
      'categoryId': _selectedCategoryId,
      'imageUrl': null,
      'unit': _unit,
      'hsnCode': null,
      'gstRate': _gstRate,
      'costPrice': buyPrice,
      'sellingPrice': sellPrice,
      'minStockLevel': minStock,
      'description': description.isNotEmpty ? description : null,
      'status': _status,
    };

    if (isEdit) {
      await ref
          .read(productNotifierProvider.notifier)
          .updateProduct(widget.productId!, data);
    } else {
      await ref.read(productNotifierProvider.notifier).createProduct(data);
    }

    if (!mounted) return;
    final notifierState = ref.read(productNotifierProvider);
    if (notifierState.hasError) {
      setState(() => _isSaving = false);
      _showSnack('${notifierState.error}', isError: true);
      return;
    }

    ref.invalidate(productsProvider(ProductFilter(search: null, page: 1)));
    if (isEdit) ref.invalidate(productDetailProvider(widget.productId!));
    context.pop();
    _showSnack(isEdit ? 'Product updated' : 'Product created');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }
}
